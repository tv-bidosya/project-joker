class_name LocalMatchHost

extends RefCounted


# Локальная модель будущего ведущего сетевой партии. Она пока не открывает
# сокеты: её задача — принимать команды так, как это будет делать Steam-хост.
const Command = preload("res://Scripts/core/MatchCommand.gd")
const Snapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")
const SoundpadManifest = preload("res://Assets/Soundboard/soundpad_manifest.gd")

const MAX_PUBLIC_TABLE_EVENTS := 48
const SOCIAL_ACTION_USE_LIMIT := 3
const SOCIAL_ACTION_COOLDOWN_MILLISECONDS := 120000
const NETWORK_REACTIONS := ["😄", "👏", "😮", "😢"]
const NETWORK_STICKERS := ["🍫", "☕", "🍺", "💋", "♥"]


var game: Game
var revision := 0
var public_history: Array[String] = []
var completed_round_history: Array[Dictionary] = []
var public_table_events: Array[Dictionary] = []
var next_public_table_event_id := 1
var social_action_state_by_player: Dictionary = {}
var last_rejection_reason := "rule_rejected"


func _init(game_state: Game) -> void:
	game = game_state


func apply_command(command) -> Dictionary:
	last_rejection_reason = "rule_rejected"
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
	var increments_revision := true
	match command.type:
		Command.Type.BID:
			accepted = _apply_bid_command(command)
		Command.Type.PLAY_CARD:
			accepted = _apply_play_card_command(command)
		Command.Type.SOCIAL_ACTION:
			accepted = _apply_social_action_command(command)
			increments_revision = false
		_:
			return _create_result(false, "unsupported_command", command.player_index)

	if not accepted:
		return _create_result(false, last_rejection_reason, command.player_index)

	if increments_revision:
		revision += 1
	return _create_result(true, "accepted", command.player_index)


func create_player_snapshot(player_index: int) -> Dictionary:
	if game == null:
		return {}
	var snapshot := Snapshot.create_player_snapshot(game, player_index, revision)
	snapshot["public_history"] = public_history.duplicate()
	snapshot["completed_rounds"] = completed_round_history.duplicate(true)
	snapshot["public_table_events"] = public_table_events.duplicate(true)
	return snapshot


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
	var snapshot := Snapshot.create_host_snapshot(game, revision)
	snapshot["public_history"] = public_history.duplicate()
	snapshot["completed_rounds"] = completed_round_history.duplicate(true)
	snapshot["public_table_events"] = public_table_events.duplicate(true)
	return snapshot


func record_current_round_started() -> void:
	if game == null or game.current_round == null or game.current_round.number <= 0:
		return

	public_history.clear()
	public_table_events.clear()
	var round := game.current_round
	var dealer_name := _get_player_name(round.dealer_index)
	public_history.append("%s. Сдающий: %s." % [_get_round_label(round), dealer_name])
	public_history.append("Козырь: %s." % round.get_trump_name())
	if _round_uses_bids(round.round_type):
		public_history.append("Заказы: ходят по кругу после сдающего.")
	else:
		public_history.append("Раздача без заказов: начинаем розыгрыш взяток.")


func start_next_round(
	cards_per_player: int,
	round_type: Round.RoundType,
	trump: Round.TrumpSuit,
	deal_cards_immediately := true
) -> bool:
	if game == null or game.current_round == null or game.current_round.state != Round.State.FINISHED:
		return false

	var previous_dealer_index := game.dealer_index
	game.advance_dealer()
	if not game.start_round(cards_per_player, round_type, trump, deal_cards_immediately):
		game.dealer_index = previous_dealer_index
		return false

	# Новая раздача — самостоятельная версия общего состояния. Это не даёт
	# клиенту применить позднюю команду из предыдущей раздачи.
	revision += 1
	return true


func _apply_bid_command(command) -> bool:
	if not command.payload.has("bid"):
		return false

	var cards_were_dealt := game.cards_are_dealt
	var bid := int(command.payload["bid"])
	if not game.place_bid(command.player_index, bid):
		return false

	public_history.append("%s заказывает %d." % [_get_player_name(command.player_index), bid])
	if not cards_were_dealt and game.cards_are_dealt:
		public_history.append("Все заказы сделаны. Карты розданы, начинается розыгрыш.")
	return true


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

	var trick_completed := game.active_trick == null and game.last_trick_winner_index >= 0
	var round_completed := game.is_round_complete()
	var player_name := _get_player_name(command.player_index)
	if card.is_joker:
		public_history.append("%s сыграл Джокером%s." % [player_name, _get_joker_history_suffix(joker_mode, declared_suit, forced_card_rank)])
	else:
		public_history.append("%s сыграл %s." % [player_name, card.get_card_name()])
	_append_public_table_event({
		"kind": "played_card",
		"actor_player_index": command.player_index,
		"card": _serialize_public_card(card),
		"trick_completed": trick_completed,
		"trick_winner_player_index": game.last_trick_winner_index if trick_completed else -1,
		"round_completed": round_completed,
		"round_number": game.current_round.number,
		"tricks_played": game.current_round.tricks_played
	})

	if trick_completed:
		public_history.append("Взятку забирает %s." % _get_player_name(game.last_trick_winner_index))
	if round_completed:
		var round_scores := game.finish_round()
		if not round_scores.is_empty():
			_record_completed_round(round_scores)
			public_history.append("Раздача завершена.")
	return true


func _apply_social_action_command(command) -> bool:
	var kind := str(command.payload.get("kind", ""))
	if kind not in ["reaction", "sticker", "soundpad"]:
		last_rejection_reason = "unsupported_social_action"
		return false

	var event := {
		"kind": kind,
		"actor_player_index": command.player_index
	}
	match kind:
		"reaction":
			var reaction := str(command.payload.get("reaction", ""))
			if reaction not in NETWORK_REACTIONS:
				last_rejection_reason = "unsupported_reaction"
				return false
			event["reaction"] = reaction
		"sticker":
			var target_player_index := int(command.payload.get("target_player_index", -1))
			var sticker := str(command.payload.get("sticker", ""))
			if target_player_index < 0 or target_player_index >= game.players.size() or target_player_index == command.player_index:
				last_rejection_reason = "invalid_sticker_target"
				return false
			if sticker not in NETWORK_STICKERS:
				last_rejection_reason = "unsupported_sticker"
				return false
			event["target_player_index"] = target_player_index
			event["sticker"] = sticker
		"soundpad":
			var sound_id := str(command.payload.get("sound_id", ""))
			if sound_id.is_empty() or sound_id not in SoundpadManifest.PATHS:
				last_rejection_reason = "unsupported_sound"
				return false
			event["sound_id"] = sound_id

	if not _try_consume_social_action(command.player_index, kind):
		return false
	_append_public_table_event(event)
	return true


func _try_consume_social_action(player_index: int, kind: String) -> bool:
	var player_state: Dictionary = social_action_state_by_player.get(player_index, {})
	var action_state: Dictionary = player_state.get(kind, {})
	var now := Time.get_ticks_msec()
	var cooldown_until := int(action_state.get("cooldown_until", 0))
	if cooldown_until > now:
		last_rejection_reason = "social_cooldown"
		return false

	var uses := int(action_state.get("uses", 0)) + 1
	if uses >= SOCIAL_ACTION_USE_LIMIT:
		action_state = {"uses": 0, "cooldown_until": now + SOCIAL_ACTION_COOLDOWN_MILLISECONDS}
	else:
		action_state = {"uses": uses, "cooldown_until": 0}
	player_state[kind] = action_state
	social_action_state_by_player[player_index] = player_state
	return true


func _append_public_table_event(event_data: Dictionary) -> void:
	var event := event_data.duplicate(true)
	event["event_id"] = next_public_table_event_id
	next_public_table_event_id += 1
	public_table_events.append(event)
	if public_table_events.size() > MAX_PUBLIC_TABLE_EVENTS:
		public_table_events.pop_front()


func _serialize_public_card(card: Card) -> Dictionary:
	if card == null:
		return {}
	return {
		"suit": card.suit,
		"rank": card.rank,
		"is_joker": card.is_joker,
		"card_key": _get_card_key(card)
	}


func _record_completed_round(round_scores: Array[int]) -> void:
	if game == null or game.current_round == null:
		return

	var player_results: Array[Dictionary] = []
	for player_index in game.players.size():
		var player := game.players[player_index]
		player_results.append({
			"bid": player.bid,
			"tricks_taken": player.tricks_taken,
			"round_score": round_scores[player_index]
		})

	completed_round_history.append({
		"round_number": game.current_round.number,
		"round_label": _get_round_label(game.current_round),
		"trump_name": game.current_round.get_trump_name(),
		"uses_bids": _round_uses_bids(game.current_round.round_type),
		"players": player_results
	})


func _round_uses_bids(round_type: Round.RoundType) -> bool:
	return round_type != Round.RoundType.GOLDEN and round_type != Round.RoundType.MISERE


func _get_round_label(round: Round) -> String:
	match round.round_type:
		Round.RoundType.DARK:
			return "Тёмная раздача %d" % round.number
		Round.RoundType.NO_TRUMP:
			return "Бескозырная раздача %d" % round.number
		Round.RoundType.GOLDEN:
			return "Золотая раздача %d" % round.number
		Round.RoundType.MISERE:
			return "Мизерная раздача %d" % round.number
		_:
			return "Обычная раздача %d · %d %s" % [round.number, round.cards_per_player, _get_cards_word(round.cards_per_player)]


func _get_cards_word(count: int) -> String:
	if count == 1:
		return "карта"
	if count >= 2 and count <= 4:
		return "карты"
	return "карт"


func _get_player_name(player_index: int) -> String:
	if game == null or player_index < 0 or player_index >= game.players.size():
		return "Игрок"
	return game.players[player_index].display_name


func _get_joker_history_suffix(joker_mode: int, declared_suit: int, forced_card_rank: int) -> String:
	var suit_symbol := _get_suit_symbol(declared_suit)
	if forced_card_rank == Trick.ForcedCardRank.HIGHEST:
		return ": %s, кладите старшую" % suit_symbol
	if forced_card_rank == Trick.ForcedCardRank.LOWEST:
		return ": %s, кладите младшую" % suit_symbol
	if joker_mode == Trick.JokerMode.JOKER_WINS:
		return ": Джокер забирает"
	if joker_mode == Trick.JokerMode.NORMAL_CARD_WINS:
		return ": Джокер сброшен"
	return ""


func _get_suit_symbol(suit: int) -> String:
	match suit:
		Card.Suit.CLUBS:
			return "♣"
		Card.Suit.SPADES:
			return "♠"
		Card.Suit.HEARTS:
			return "♥"
		Card.Suit.DIAMONDS:
			return "♦"
		_:
			return "масть не выбрана"


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
