class_name MatchStateSnapshot

extends RefCounted


# Снимки состояния для будущего онлайна. Они не восстанавливают Game и не
# передаются по сети в текущей версии: задача класса — заранее отделить
# общедоступный стол от закрытых рук игроков.
static func create_host_snapshot(game: Game, revision: int) -> Dictionary:
	var snapshot := create_public_snapshot(game, revision)
	var private_hands: Array[Dictionary] = []

	for player in game.players:
		private_hands.append({
			"player_index": player.player_id,
			"cards": _serialize_cards(player.hand)
		})

	snapshot["deck_cards"] = _serialize_cards(game.deck.cards)
	snapshot["private_hands"] = private_hands
	return snapshot


static func create_player_snapshot(game: Game, recipient_player_index: int, revision: int) -> Dictionary:
	if recipient_player_index < 0 or recipient_player_index >= game.players.size():
		return {}

	var snapshot := create_public_snapshot(game, revision)
	snapshot["recipient_player_index"] = recipient_player_index
	snapshot["private_hand"] = _serialize_cards(game.players[recipient_player_index].hand)
	return snapshot


static func create_public_snapshot(game: Game, revision: int) -> Dictionary:
	var public_players: Array[Dictionary] = []
	for player in game.players:
		public_players.append({
			"player_index": player.player_id,
			"display_name": player.display_name,
			"cards_in_hand": player.hand.size(),
			"bid": player.bid,
			"tricks_taken": player.tricks_taken,
			"total_score": player.total_score,
			"exact_orders_completed": player.exact_orders_completed
		})

	return {
		"revision": revision,
		"round_number": game.round_number,
		"dealer_index": game.dealer_index,
		"last_trick_winner_index": game.last_trick_winner_index,
		"cards_are_dealt": game.cards_are_dealt,
		"cards_left_in_deck": game.deck.cards_left(),
		"trump_card": _serialize_card(game.trump_card),
		"players": public_players,
		"round": _serialize_round(game.current_round),
		"active_trick": _serialize_trick(game.active_trick),
		"last_completed_trick": {
			"cards": _serialize_cards(game.last_completed_trick_cards),
			"played_by": game.last_completed_trick_played_by.duplicate(),
			"joker_mode": game.last_completed_trick_joker_mode,
			"declared_suit": game.last_completed_trick_declared_suit,
			"forced_card_rank": game.last_completed_trick_forced_card_rank
		}
	}


static func is_player_snapshot_safe(snapshot: Dictionary, recipient_player_index: int) -> bool:
	if snapshot.is_empty() or int(snapshot.get("recipient_player_index", -1)) != recipient_player_index:
		return false
	if snapshot.has("deck_cards") or snapshot.has("private_hands"):
		return false
	if not snapshot.has("private_hand"):
		return false

	for player_data_variant in snapshot.get("players", []):
		if not (player_data_variant is Dictionary):
			return false
		var player_data: Dictionary = player_data_variant
		if player_data.has("hand") or player_data.has("cards"):
			return false

	return true


static func _serialize_round(round: Round) -> Dictionary:
	return {
		"number": round.number,
		"cards_per_player": round.cards_per_player,
		"round_type": round.round_type,
		"trump": round.trump,
		"dealer_index": round.dealer_index,
		"current_player_index": round.current_player_index,
		"lead_player_index": round.lead_player_index,
		"bids": round.bids.duplicate(),
		"bids_made": round.bids_made,
		"tricks_played": round.tricks_played,
		"state": round.state
	}


static func _serialize_trick(trick: Trick) -> Dictionary:
	if trick == null:
		return {}

	return {
		"leader_index": trick.leader_index,
		"current_player_index": trick.current_player_index,
		"lead_suit": trick.lead_suit,
		"trump": trick.trump,
		"joker_mode": trick.joker_mode,
		"declared_suit": trick.declared_suit,
		"forced_card_rank": trick.forced_card_rank,
		"played_cards": _serialize_cards(trick.played_cards),
		"played_by": trick.played_by.duplicate()
	}


static func _serialize_cards(cards: Array[Card]) -> Array[Dictionary]:
	var serialized_cards: Array[Dictionary] = []
	for card in cards:
		serialized_cards.append(_serialize_card(card))
	return serialized_cards


static func _serialize_card(card: Card) -> Dictionary:
	if card == null:
		return {}

	return {
		"suit": card.suit,
		"rank": card.rank,
		"is_joker": card.is_joker,
		"card_key": "joker" if card.is_joker else "%d_%d" % [card.suit, card.rank]
	}
