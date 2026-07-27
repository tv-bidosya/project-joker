extends SceneTree


const LoopbackNetwork = preload("res://Scripts/core/LoopbackNetworkTest.gd")
const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")
const MatchCommand = preload("res://Scripts/core/MatchCommand.gd")
const Snapshot = preload("res://Scripts/core/MatchStateSnapshot.gd")


func _init() -> void:
	_test_disconnect_temporary_bot_and_return()
	_test_disconnect_during_first_turn_roll()
	_test_undo_rejection_timeout_and_limit()
	_test_afk_pauses_during_undo_vote()
	print("NETWORK_RESILIENCE_TEST_PASS")
	quit()


func _test_disconnect_temporary_bot_and_return() -> void:
	var network_match := SteamP2PMatch.new()
	network_match.mode = LoopbackNetwork.Mode.HOST
	network_match.lobby_round_started = true

	var game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	game.dealer_index = 0
	assert(game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	network_match.match_host = MatchHost.new(game)
	network_match.match_host.record_current_round_started()

	const OLD_PEER_ID := 22
	const NEW_PEER_ID := 33
	const PLAYER_STEAM_ID := 76561198000000001
	const PLAYER_INDEX := 1
	network_match._connected_player_by_peer[OLD_PEER_ID] = PLAYER_INDEX
	network_match._connected_client_peers_by_player[PLAYER_INDEX] = OLD_PEER_ID
	network_match._confirmed_client_peers_by_player[PLAYER_INDEX] = OLD_PEER_ID
	network_match._steam_id_by_peer_id[OLD_PEER_ID] = PLAYER_STEAM_ID
	network_match._player_index_by_steam_id[PLAYER_STEAM_ID] = PLAYER_INDEX

	var original_hand_keys := _get_hand_keys(game.players[PLAYER_INDEX].hand)
	network_match._on_steam_peer_disconnected(OLD_PEER_ID)
	assert(network_match.is_match_paused_for_reconnect())
	assert(network_match.get_reconnecting_player_indices() == [PLAYER_INDEX])
	assert(network_match._get_active_human_player_index() == -1)
	network_match._process_human_auto_turn(500.0)
	network_match._process_local_bots(500.0)
	assert(network_match.match_host.revision == 0, "Reconnect pause must block bots and AFK actions.")

	var waiting_snapshot: Dictionary = network_match._append_reconnect_state(
		network_match.match_host.create_player_snapshot(PLAYER_INDEX)
	)
	assert(Snapshot.is_player_snapshot_safe(waiting_snapshot, PLAYER_INDEX))
	assert(waiting_snapshot.get("reconnecting_player_indices", []) == [PLAYER_INDEX])
	assert(waiting_snapshot.get("temporary_bot_player_indices", []).is_empty())

	assert(network_match.replace_reconnecting_player_with_bot(PLAYER_INDEX))
	assert(not network_match.is_match_paused_for_reconnect())
	assert(network_match.get_temporary_bot_player_indices() == [PLAYER_INDEX])
	network_match._bot_action_delay_seconds = 0.0
	network_match._process_local_bots(0.1)
	assert(network_match.match_host.revision == 1, "The temporary bot must continue the disconnected player's turn.")
	assert(game.players[PLAYER_INDEX].bid >= 0)
	assert(_get_hand_keys(game.players[PLAYER_INDEX].hand) == original_hand_keys)

	var bot_snapshot: Dictionary = network_match._append_reconnect_state(
		network_match.match_host.create_player_snapshot(PLAYER_INDEX)
	)
	assert(Snapshot.is_player_snapshot_safe(bot_snapshot, PLAYER_INDEX))
	assert(bot_snapshot.get("temporary_bot_player_indices", []) == [PLAYER_INDEX])
	assert(bot_snapshot.get("private_hand", []).size() == original_hand_keys.size())

	network_match._steam_id_by_peer_id[NEW_PEER_ID] = PLAYER_STEAM_ID
	assert(
		network_match._assign_client_player_index(NEW_PEER_ID, PLAYER_INDEX) == PLAYER_INDEX,
		"The same Steam account must reclaim its reserved seat."
	)
	assert(not network_match._local_bot_player_indices.has(PLAYER_INDEX))
	assert(network_match.get_temporary_bot_player_indices().is_empty())
	assert(network_match._connected_client_peers_by_player.get(PLAYER_INDEX, 0) == NEW_PEER_ID)
	assert(_get_hand_keys(game.players[PLAYER_INDEX].hand) == original_hand_keys)

	var returned_snapshot: Dictionary = network_match._append_reconnect_state(
		network_match.match_host.create_player_snapshot(PLAYER_INDEX)
	)
	assert(Snapshot.is_player_snapshot_safe(returned_snapshot, PLAYER_INDEX))
	assert(returned_snapshot.get("private_hand", []).size() == original_hand_keys.size())
	assert(not returned_snapshot.has("deck_cards"))
	assert(not returned_snapshot.has("private_hands"))
	network_match.free()


func _test_disconnect_during_first_turn_roll() -> void:
	var network_match := SteamP2PMatch.new()
	network_match.mode = LoopbackNetwork.Mode.HOST
	network_match.match_host = MatchHost.new(Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"]))
	network_match._expected_remote_player_count = 3
	network_match._confirmed_client_peers_by_player = {1: 21, 2: 22, 3: 23}
	assert(network_match.begin_first_turn_roll())

	const PLAYER_INDEX := 2
	network_match._reconnecting_player_indices[PLAYER_INDEX] = true
	assert(not network_match.first_turn_roll_submitted[PLAYER_INDEX])
	assert(network_match.replace_reconnecting_player_with_bot(PLAYER_INDEX))
	assert(
		network_match.first_turn_roll_submitted[PLAYER_INDEX],
		"A temporary bot must roll for a disconnected contender so the table cannot deadlock."
	)
	network_match.free()


func _test_undo_rejection_timeout_and_limit() -> void:
	var game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	game.dealer_index = 0
	assert(game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	var match_host := MatchHost.new(game)
	var actor_index := game.current_round.current_player_index
	assert(_apply_bid(match_host, actor_index, 0))

	assert(_request_undo(match_host, actor_index))
	var rejecting_player_index := (actor_index + 1) % game.players.size()
	var reject_command := MatchCommand.new(
		MatchCommand.Type.UNDO_VOTE,
		rejecting_player_index,
		game.round_number,
		match_host.revision,
		{"approved": false}
	)
	assert(bool(match_host.apply_command(reject_command).get("accepted", false)))
	assert(not match_host.is_undo_vote_pending())
	assert(game.players[actor_index].bid == 0, "A rejected undo must preserve the accepted bid.")

	assert(_request_undo(match_host, actor_index))
	match_host.undo_deadline_milliseconds = Time.get_ticks_msec() - 1
	assert(match_host.process_undo_vote())
	assert(not match_host.is_undo_vote_pending())
	assert(game.players[actor_index].bid == 0, "An undo timeout must preserve the accepted bid.")

	var third_request := MatchCommand.new(
		MatchCommand.Type.UNDO_REQUEST,
		actor_index,
		game.round_number,
		match_host.revision
	)
	var third_result: Dictionary = match_host.apply_command(third_request)
	assert(not bool(third_result.get("accepted", false)))
	assert(
		str(third_result.get("reason", "")) == "undo_unavailable",
		"A player may not exceed two undo requests for the same decision."
	)

	var stale_bid := MatchCommand.new(
		MatchCommand.Type.BID,
		game.current_round.current_player_index,
		game.round_number,
		match_host.revision - 1,
		{"bid": 0}
	)
	var stale_result: Dictionary = match_host.apply_command(stale_bid)
	assert(not bool(stale_result.get("accepted", false)))
	assert(str(stale_result.get("reason", "")) == "outdated_revision")


func _test_afk_pauses_during_undo_vote() -> void:
	var network_match := SteamP2PMatch.new()
	network_match.mode = LoopbackNetwork.Mode.HOST
	network_match.lobby_round_started = true
	var game := Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"])
	game.dealer_index = 3
	assert(game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS))
	network_match.match_host = MatchHost.new(game)

	assert(network_match._submit_local_bot_action(0, true))
	assert(_request_undo(network_match.match_host, 0))
	var revision_during_vote: int = network_match.match_host.revision
	network_match._process_human_auto_turn(500.0)
	assert(
		network_match.match_host.revision == revision_during_vote,
		"AFK auto-turn must remain paused while an undo vote is open."
	)

	var reject_command := MatchCommand.new(
		MatchCommand.Type.UNDO_VOTE,
		1,
		game.round_number,
		network_match.match_host.revision,
		{"approved": false}
	)
	assert(bool(network_match.match_host.apply_command(reject_command).get("accepted", false)))
	var revision_after_vote: int = network_match.match_host.revision
	network_match._reset_human_auto_turn()
	network_match._process_human_auto_turn(0.0)
	network_match._process_human_auto_turn(120.1)
	assert(network_match.match_host.revision == revision_after_vote)
	assert(network_match._human_auto_turn_enabled_by_player.has(1))
	network_match._process_human_auto_turn(0.0)
	network_match._process_human_auto_turn(60.1)
	assert(
		network_match.match_host.revision == revision_after_vote + 1,
		"AFK auto-turn must resume after the undo vote closes."
	)
	network_match.free()


func _apply_bid(match_host, player_index: int, bid: int) -> bool:
	var command := MatchCommand.new(
		MatchCommand.Type.BID,
		player_index,
		match_host.game.round_number,
		match_host.revision,
		{"bid": bid}
	)
	return bool(match_host.apply_command(command).get("accepted", false))


func _request_undo(match_host, player_index: int) -> bool:
	var command := MatchCommand.new(
		MatchCommand.Type.UNDO_REQUEST,
		player_index,
		match_host.game.round_number,
		match_host.revision
	)
	return bool(match_host.apply_command(command).get("accepted", false))


func _get_hand_keys(hand: Array[Card]) -> Array[String]:
	var keys: Array[String] = []
	for card in hand:
		keys.append("joker" if card.is_joker else "%d_%d" % [card.suit, card.rank])
	return keys
