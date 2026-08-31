extends SceneTree

class OfflineBridge extends SteamBridge:
	var state: Dictionary = {}
	func get_lobby_state() -> Dictionary:
		return state
	func get_local_steam_id() -> int:
		return 42
	func is_multiplayer_peer_transport_available() -> bool:
		return false

var scene: Variant
var bridge := OfflineBridge.new()
var cyrillic := RegEx.new()
var failures: Array[String] = []
const NEW_KEYS = ["Сетевая пауза","Сетевая раздача продолжается у хоста. Здесь можно безопасно вернуться в комнату или открыть личные настройки.","Вернуться в Steam-комнату","Расписка и история на столе показывают только публичные данные."," · команда не выбрана"," · хост","… ждём","✓ готов","%s · мест %d/2","2×2 · %s против %s","Бот %d — ✓ готов · %s","Бот %d · %s — ✓ готов · %s","Готов ✓ (отменить)","ещё не подключён","Заполнить место %d ботом","Игра приостановлена: ждём переподключения игроков.","Игрок","Исключить %s из комнаты","классическая игра","Комната: %d\nРежим: %s\nУчастники: %d из %d\nИстория: %s\nДоступ: %s · состояние: %s · протокол %d","лёгкий","обычный","сложный","ожидание","партия идёт","Место %d: игрок отключился. Можно подождать или временно передать место боту.","Первый ход определён. Ждём начала первой раздачи.","Подключаемся к игровому столу…","подключён","Свободное место %d","Сетевой стол ещё не подключён. Все участники отмечают готовность и нажимают «Подключиться к игровому столу».","Сетевой стол подключён. Раздача %d · %s.","Стол подключён. Ожидаем остальных игроков.","Статус Steam-комнаты не получен.","Убрать ботов","Участники комнаты\n%s","Steam: %s\nПосле создания появятся ID комнаты и число участников.","списку комнат","приглашению Steam","%s пригласил тебя в Steam-комнату. Прими приглашение в Steam.","Активной Steam-комнаты нет.","Ботов можно добавить только внутри Steam-комнаты.","Боты убраны из свободных мест.","В выбранной команде уже два игрока.","Входим в Steam-комнату по %s…","Готовность можно отметить только внутри Steam-комнаты.","Готовность отменена.","Заполнять свободные места ботами может только хост.","Игрок исключён из комнаты.","Исключать игроков можно только до начала партии.","Команда выбрана. Подтверди готовность после настройки комнаты.","Комната уже создана.","Название команды может менять только её капитан.","Название команды обновлено.","Не удалось войти в Steam-комнату. Код ответа: %d.","Не удалось установить Steam P2P-связь с %s. Код: %d.","Режим истории матча может менять только хост.","Режим истории матча обновлён.","Режим истории можно выбрать только внутри Steam-комнаты.","Свободные места заполнены ботами.","Сложность сетевых ботов может менять только хост.","Сложность сетевых ботов можно выбрать только внутри Steam-комнаты.","Сложность сетевых ботов обновлена.","Сначала выйди из текущей Steam-комнаты.","Сначала подключи Steam-клиент.","Сначала создай или зайди в Steam-комнату.","Создаём Steam-комнату «%s» на четыре места…","Состав Steam-комнаты обновлён.","Ты вошёл в Steam-комнату. Отметь готовность, когда все соберутся.","Ты вышел из Steam-комнаты.","Ты готов к сетевой партии.","Ты находишься в Steam-комнате. Ожидаем игроков.","Ты уже находишься в этой Steam-комнате.","Хост исключил тебя из комнаты.","Хост исключил тебя из этой комнаты.","Steam не передал ID комнаты при запуске.","Steam не создал комнату. Код результата: %d.","Steam открыл диалог приглашения для этой комнаты.","Steam передал некорректный ID комнаты.","Steam API не позволяет изменить режим истории в этой среде.","Steam API не позволяет изменить сложность ботов в этой среде.","Steam API не позволяет изменить состав комнаты в этой среде.","Steam API не предоставляет вход в комнаты в этой среде.","Steam API не предоставляет отметку готовности в этой среде.","Steam API не предоставляет создание комнат в этой среде.","Steam Overlay с приглашениями недоступен в этой среде.","Steam-комната «%s» создана. Ожидаем игроков.","Steam-комната ещё не создана."]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	cyrillic.compile("[А-Яа-яЁё]")
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.persistent_settings_writes_enabled = false
	scene.persistent_settings_path = "user://steam_room_probe_%d.cfg" % Time.get_ticks_usec()
	scene.session_save_path = "user://steam_room_probe_%d.save" % Time.get_ticks_usec()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	scene.steam_bridge = bridge
	scene.steam_p2p_match.set_process(false)
	for locale in ["en", "uk", "pl", "be", "kz", "ru", "en"]:
		scene.interface_locale = locale
		TranslationServer.set_locale(locale)
		var dictionary: Translation = load("res://Localization/interface.%s.translation" % locale)
		for key in NEW_KEYS:
			_check(not str(dictionary.get_message(key)).is_empty(), "Missing translation: %s / %s" % [locale, key])
		scene._build_network_pause_menu_content()
		_check(tr("Сетевая пауза") in _texts(scene.menu_content), "Network pause title")
		_check(tr("Вернуться в Steam-комнату") in _texts(scene.menu_content), "Return button")
		_check_english("network pause", locale)
		for state_name in ["offline", "empty", "waiting", "ready", "bots", "teams"]:
			bridge.state = _state(state_name)
			scene._show_steam_lobby_menu()
			_check_english("room " + state_name, locale)
			if state_name in ["ready", "bots", "teams"]:
				_check(scene.steam_lobby_ready_button.text == tr("Готов ✓ (отменить)"), "Ready label")
			if state_name == "bots":
				_check((tr("Бот %d — ✓ готов · %s") % [1, tr("обычный")]) in scene.steam_lobby_members_label.text, "Bot label")
			await process_frame
		for key in NEW_KEYS:
			if "%" not in key and "\n" not in key:
				_check(scene._localize_steam_lobby_status(key) == tr(key), "Static room status")
		var dynamic_cases := [
			["Создаём Steam-комнату «%s» на четыре места…", ["только для друзей"], [tr("только для друзей")]],
			["Steam-комната «%s» создана. Ожидаем игроков.", ["по приглашению"], [tr("по приглашению")]],
			["Входим в Steam-комнату по %s…", ["списку комнат"], [tr("списку комнат")]],
			["Не удалось войти в Steam-комнату. Код ответа: %d.", [4], [4]],
			["Steam не создал комнату. Код результата: %d.", [16], [16]],
			["%s пригласил тебя в Steam-комнату. Прими приглашение в Steam.", ["Профиль"], ["Профиль"]],
			["Не удалось установить Steam P2P-связь с %s. Код: %d.", ["Олег", 5], ["Олег", 5]],
		]
		for entry in dynamic_cases:
			var raw: String = entry[0] % entry[1]
			_check(scene._localize_steam_lobby_status(raw) == tr(entry[0]) % entry[2], "Dynamic status: " + raw)
		bridge.state = _state("bots")
		var match_node = scene.steam_p2p_match
		match_node.mode = match_node.Mode.HOST
		match_node._transport_active = true
		var game := Game.new(["Alice", "Bob", "Carol", "Dave"])
		_check(game.start_round(1, Round.RoundType.NORMAL, Round.TrumpSuit.CLUBS), "Start test round")
		match_node.match_host = LocalMatchHost.new(game)
		match_node.lobby_round_started = true
		var raw_status := "Steam P2P: начата первая обычная раздача. Хост раздал по одной карте и ждёт подтверждение личных рук."
		match_node.status_text = raw_status
		bridge.state["match_state"] = SteamBridge.LOBBY_STATE_PLAYING
		for round_state in [Round.State.BIDDING, Round.State.PLAYING, Round.State.FINISHED]:
			game.current_round.state = round_state
			scene._show_steam_lobby_menu()
			_check_english("connected room", locale)
			_check("1" in scene.steam_p2p_status_label.text, "Round number")
			_check(match_node.status_text == raw_status, "Raw diagnostic must remain untouched")
		match_node._reconnecting_player_indices[1] = true
		scene._refresh_steam_lobby_status()
		_check(scene.steam_p2p_status_label.text == tr("Игра приостановлена: ждём переподключения игроков."), "Reconnect status")
		_check_english("reconnecting room", locale)
		match_node._reconnecting_player_indices.clear()
		match_node.lobby_round_started = false
		_check(scene._get_steam_table_connection_text() == tr("Стол подключён. Ожидаем остальных игроков."), "Waiting status")
		match_node.first_turn_roll_phase = match_node.FirstTurnRollPhase.WAITING
		_check(scene._get_steam_table_connection_text() == tr("Розыгрыш первого хода идёт"), "Dice roll status")
		match_node.first_turn_roll_phase = match_node.FirstTurnRollPhase.COMPLETE
		match_node.first_turn_roll_winner_index = 0
		_check(scene._get_steam_table_connection_text() == tr("Первый ход определён. Ждём начала первой раздачи."), "Completed dice roll status")
		match_node.first_turn_roll_phase = match_node.FirstTurnRollPhase.INACTIVE
		match_node.first_turn_roll_winner_index = -1
		match_node.mode = match_node.Mode.CLIENT
		_check(scene._get_steam_table_connection_text() == tr("Подключаемся к игровому столу…"), "Client connection status")
		match_node.mode = match_node.Mode.NONE
		match_node._transport_active = false
		match_node.match_host = null
		await process_frame
	bridge.state = _state("teams")
	bridge.state.members[0]["name"] = "Олег"
	bridge.state["team_names"] = ["Профиль", "Настройки"]
	scene._show_steam_lobby_menu()
	_check("Олег" in scene.steam_lobby_members_label.text, "Player names must not be translated")
	_check("Профиль" in scene.steam_lobby_details_label.text and "Настройки" in scene.steam_lobby_details_label.text, "Custom team names must not be translated")
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	for locale in ["en", "uk", "pl", "be", "kz", "ru"]:
		scene.interface_locale = locale
		TranslationServer.set_locale(locale)
		scene._build_network_pause_menu_content()
		_check_english("mobile network pause", locale)
		_check(tr("Вернуться в Steam-комнату").to_upper() in _texts(scene.menu_content), "Mobile return tile")
		bridge.state = _state("bots")
		scene._show_steam_lobby_menu()
		_check_english("mobile room", locale)
		await process_frame
	scene.queue_free()
	await process_frame
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("STEAM_ROOM_SIX_LOCALES_AND_STATES_PASS")
	print("NETWORK_PAUSE_DESKTOP_MOBILE_PASS")
	print("STEAM_LOBBY_LOCALIZATION_TEST_PASS")
	quit()

func _state(kind: String) -> Dictionary:
	var state := {
		"initialized": kind != "offline", "lobby_id": 0 if kind in ["offline", "empty"] else 12345,
		"status": "Ты готов к сетевой партии." if kind in ["ready", "bots", "teams"] else "Готовность отменена.",
		"local_ready": kind in ["ready", "bots", "teams"], "lobby_owner": 42,
		"member_count": 2, "member_limit": 4, "bot_count": 2 if kind in ["bots", "teams"] else 0,
		"fill_empty_seats_with_bots": kind in ["bots", "teams"], "bot_difficulty": 1,
		"history_mode": 0, "visibility_label": "только для друзей",
		"match_state": SteamBridge.LOBBY_STATE_WAITING,
		"match_mode": SteamBridge.MATCH_MODE_TEAMS_2V2 if kind == "teams" else SteamBridge.MATCH_MODE_CLASSIC,
		"team_names": ["Команда 1", "Команда 2"], "team_counts": [1, 1],
		"local_team_id": 0, "local_is_team_captain": true,
		"members": [
			{"name": "Alice", "steam_id": 42, "is_owner": true, "ready": kind != "waiting", "team_id": 0},
			{"name": "Bob", "steam_id": 43, "ready": kind != "waiting", "team_id": 1},
		]
	}
	return state

func _texts(node: Node) -> Array[String]:
	var result: Array[String] = []
	for child in node.get_children():
		if child is Label or child is Button:
			result.append(child.text)
		if child is LineEdit:
			result.append(child.text)
			result.append(child.placeholder_text)
		if child is OptionButton:
			for i in child.item_count:
				result.append(child.get_item_text(i))
		if child is Control:
			result.append(child.tooltip_text)
		result.append_array(_texts(child))
	return result

func _check_english(page: String, locale: String) -> void:
	if locale != "en":
		return
	for value in _texts(scene.menu_content):
		_check(cyrillic.search(value) == null, page + ": " + value)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
