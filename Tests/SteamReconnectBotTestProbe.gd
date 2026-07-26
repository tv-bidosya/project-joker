extends SceneTree


const MatchHost = preload("res://Scripts/core/LocalMatchHost.gd")


func _init() -> void:
	var network_match := SteamP2PMatch.new()
	network_match.mode = LoopbackNetworkTest.Mode.HOST
	network_match.match_host = MatchHost.new(Game.new(["Хост", "Игрок 2", "Игрок 3", "Игрок 4"]))
	var first_nine_card_plan: Dictionary = network_match._get_scheduled_round_plan(9)
	assert(int(first_nine_card_plan.get("trump", -1)) == Round.TrumpSuit.CLUBS, "Первая девятикарточная раздача должна показывать трефовый козырь.")
	network_match._reconnecting_player_indices[2] = true
	network_match._player_index_by_steam_id[12345] = 2

	assert(network_match.is_match_paused_for_reconnect(), "Отключённый игрок должен приостанавливать сетевую партию.")
	assert(network_match.replace_reconnecting_player_with_bot(2), "Хост должен суметь временно заменить отключённого игрока ботом.")
	assert(not network_match.is_match_paused_for_reconnect(), "После временной замены партия должна продолжиться.")
	assert(network_match._local_bot_player_indices.has(2), "Временный бот должен управлять тем же местом.")
	assert(network_match.get_temporary_bot_player_indices().has(2), "Снимок должен помечать место временного бота.")
	assert(network_match._player_index_by_steam_id.get(12345, -1) == 2, "Место должно остаться закреплено за Steam ID игрока.")

	network_match._restore_temporary_bot_for_reconnect(2)
	assert(not network_match._local_bot_player_indices.has(2), "Вернувшийся игрок должен убрать временного бота.")
	assert(not network_match.get_temporary_bot_player_indices().has(2), "После возвращения пометка временного бота должна исчезнуть.")
	assert(network_match._player_index_by_steam_id.get(12345, -1) == 2, "Игрок должен вернуться на прежнее место.")

	var bot_game := Game.new(["Хост", "Бот", "Игрок 3", "Игрок 4"])
	assert(bot_game.start_round(2, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Тестовая раздача бота должна запускаться.")
	var bot_player_index := bot_game.current_round.current_player_index
	var bot_player: Player = bot_game.players[bot_player_index]
	bot_player.hand.clear()
	var trump_ace := Card.new()
	trump_ace.suit = Card.Suit.CLUBS
	trump_ace.rank = Card.Rank.ACE
	bot_player.receive_card(trump_ace)
	var joker := Card.new()
	joker.is_joker = true
	bot_player.receive_card(joker)
	network_match.match_host = MatchHost.new(bot_game)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_EASY
	var easy_bid := network_match._get_local_bot_bid(bot_player_index, bot_game.current_round)
	network_match._bot_difficulty = SteamP2PMatch.BOT_DIFFICULTY_HARD
	var hard_bid := network_match._get_local_bot_bid(bot_player_index, bot_game.current_round)
	assert(easy_bid == 0, "Лёгкий сетевой бот должен выбирать простое минимальное решение.")
	assert(hard_bid == 2, "Сложный сетевой бот должен учитывать Джокера и старший козырь.")

	network_match.free()
	print("STEAM_RECONNECT_BOT_TEST_PASS")
	quit()
