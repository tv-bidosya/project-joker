extends SceneTree

class MobileStartup extends "res://Scripts/core/GameManager.gd":
	func _apply_mobile_table_layout() -> void:
		mobile_table_layout = true
		super()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Variant = load("res://Scenes/main.tscn").instantiate()
	scene.set_script(MobileStartup)
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://mobile_history_safe_area_probe.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	scene.menu_overlay.hide()
	scene.first_turn_roll_panel.hide()
	scene.stage_announcement_overlay.hide()
	scene._reset_game_session()
	scene.game.current_round.state = Round.State.PLAYING
	scene.game.current_round.current_player_index = 0
	scene.game.current_round.lead_player_index = 0
	scene.game.cards_are_dealt = true
	scene._relayout_phone_table()
	for frame in 8:
		await process_frame

	var history_button: Rect2 = scene.round_history_toggle_button.get_global_rect()
	var history_panel: Rect2 = scene.round_history_panel.get_global_rect()
	var left_panel: Rect2 = scene.player_panels[1].get_global_rect()
	print("HISTORY_RECTS ", history_button, " ", history_panel, " LEFT ", left_panel)
	assert(history_panel.position.x >= history_button.end.x, "History opens to the right of its button")
	assert(history_panel.size.x <= 410.0, "History must remain a narrow vertical reading lane")
	assert(history_panel.end.y < left_panel.position.y, "History must clear the left player")
	assert(left_panel.position.x >= scene.PhoneTable.SAFE_LEFT, "Left player must clear the phone cutout")
	assert(scene.tutorial_panel.global_position.x >= scene.PhoneTable.SAFE_LEFT)
	assert(scene.action_label.get_global_rect().end.y <= scene.player_panels[0].get_global_rect().position.y)
	assert(scene.player_panels[0].get_global_rect().end.y <= scene.hand_container.get_global_rect().position.y)
	print("MOBILE_SAFE_AREA_HISTORY_RECTS_PASS")

	scene.recent_actions.clear()
	scene._add_history_round_start("ROUND_START_WITH_DEALER", "ROUND_NORMAL", 13, 13, "Azriel", "")
	scene._add_history_event("ACTION_PLAYER_BID", ["Cassian", 1])
	var card: Card = scene._create_card(Card.Suit.HEARTS, Card.Rank.QUEEN)
	scene._add_history_card_play("Rhysand", card)
	scene._add_history_event("ACTION_TRICK_WINNER", ["Azriel"])
	scene._add_history_joker_rule(Trick.JokerMode.HIGHEST_DECLARED_CARD_WINS, Card.Suit.CLUBS, Trick.ForcedCardRank.NONE, true)
	scene._add_history_event("HISTORY_NEXT_DEALER", ["Cassian"])
	scene._add_history_event("ACTION_TIMEOUT_BID", [2])
	var signatures: Dictionary = {}
	var expected := {
		"en": ["Normal 13 of 13", "Cassian bids 1", "Next dealer", "Time is up"],
		"uk": ["Звичайна 13 з 13", "Cassian замовляє 1", "Наступним здає", "Час вийшов"],
		"pl": ["Zwykła 13 z 13", "Cassian licytuje 1", "Następny rozdaje", "Czas minął"],
		"be": ["Звычайная 13 з 13", "Cassian заказвае 1", "Наступным здае", "Час скончыўся"],
		"kz": ["Қалыпты 13/13", "Cassian 1 тапсырыс берді", "Келесі таратушы", "Уақыт аяқталды"],
		"ru": ["Обычная 13 из 13", "Cassian заказывает 1", "Следующим сдаёт", "Время вышло"],
	}
	for locale in expected:
		TranslationServer.set_locale(locale)
		var text := "\n".join(scene._get_localized_history_lines(scene.recent_actions))
		signatures[locale] = text
		assert("@history:" not in text)
		for fragment in expected[locale]:
			assert(fragment in text, "Missing " + locale + " history fragment: " + fragment + "\n" + text)
	for first_locale in signatures:
		for second_locale in signatures:
			if first_locale != second_locale:
				assert(signatures[first_locale] != signatures[second_locale], "Every locale must rebuild the history text")
	print("MOBILE_HISTORY_SIX_LOCALES_PASS")

	TranslationServer.set_locale("ru")
	scene.pending_joker_card = scene._create_card(Card.Suit.SPADES, Card.Rank.SEVEN, true)
	scene.game.active_trick = null
	scene.pending_joker_suit = Card.Suit.HEARTS
	scene._refresh_joker_controls()
	for frame in 8:
		await process_frame
	var joker_rect: Rect2 = scene.joker_controls.get_global_rect()
	assert(joker_rect.end.y < scene.player_panels[0].get_global_rect().position.y)
	for child in scene.joker_controls.get_children():
		var button := child as Button
		assert(button != null and button.custom_minimum_size.y >= 72)
		assert(button.get_theme_font_size("font_size") >= 22)
		assert(button.get_theme_stylebox("normal") is StyleBoxTexture)
	print("MOBILE_JOKER_GREEN_BUTTONS_PASS")

	scene.queue_free()
	await process_frame
	quit()
