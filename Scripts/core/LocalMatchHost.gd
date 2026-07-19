class_name LocalMatchHost

extends RefCounted


# Локальная модель будущего ведущего сетевой партии. Она пока не открывает
# сокеты: её задача — принимать команды так, как это будет делать Steam-хост.
const Command = preload("res://Scripts/core/MatchCommand.gd")
const Snapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")


var game: Game
var revision := 0


func _init(game_state: Game) -> void:
	game = game_state


func apply_command(command) -> Dictionary:
	if game == null:
		return _create_result(false, "host_not_ready", -1)
	if command == null or not command.is_valid():
		return _create_result(false, "invalid_command", -1)
	if command.round_number != game.round_number:
		return _create_result(false, "wrong_round", command.player_index)
	if command.revision != revision:
		return _create_result(false, "outdated_revision", command.player_index)
	if command.player_index < 0 or command.player_index >= game.players.size():
		return _create_result(false, "invalid_player", command.player_index)

	var accepted := false
	match command.type:
		Command.Type.BID:
			accepted = _apply_bid_command(command)
		Command.Type.PLAY_CARD:
			accepted = _apply_play_card_command(command)
		_:
			return _create_result(false, "unsupported_command", command.player_index)

	if not accepted:
		return _create_result(false, "rule_rejected", command.player_index)

	revision += 1
	return _create_result(true, "accepted", command.player_index)


func create_player_snapshot(player_index: int) -> Dictionary:
	if game == null:
		return {}
	return Snapshot.create_player_snapshot(game, player_index, revision)


func create_all_player_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	if game == null:
		return snapshots

	for player_index in game.players.size():
		snapshots.append(create_player_snapshot(player_index))
	return snapshots


func create_host_snapshot() -> Dictionary:
	if game == null:
		return {}
	return Snapshot.create_host_snapshot(game, revision)


func _apply_bid_command(command) -> bool:
	if not command.payload.has("bid"):
		return false
	return game.place_bid(command.player_index, int(command.payload["bid"]))


func _apply_play_card_command(command) -> bool:
	if not command.payload.has("card_key"):
		return false

	var card_key := str(command.payload["card_key"])
	var card := _find_card_by_key(game.players[command.player_index].hand, card_key)
	if card == null:
		return false

	var joker_mode := int(command.payload.get("joker_mode", Trick.JokerMode.NONE))
	var declared_suit := int(command.payload.get("declared_suit", -1))
	var forced_card_rank := int(command.payload.get("forced_card_rank", Trick.ForcedCardRank.NONE))
	if not game.play_card(command.player_index, card, joker_mode, declared_suit, forced_card_rank):
		return false
	if game.is_round_complete():
		game.finish_round()
	return true


func _find_card_by_key(hand: Array[Card], card_key: String) -> Card:
	for card in hand:
		if _get_card_key(card) == card_key:
			return card
	return null


func _get_card_key(card: Card) -> String:
	if card.is_joker:
		return "joker"
	return "%d_%d" % [card.suit, card.rank]


func _create_result(accepted: bool, reason: String, actor_player_index: int) -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"revision": revision,
		"actor_player_index": actor_player_index
	}
