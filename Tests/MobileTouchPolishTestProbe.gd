extends SceneTree

class MobileStartup extends "res://Scripts/core/GameManager.gd":
	func _apply_mobile_table_layout() -> void:
		mobile_table_layout = true
		super()

var scene: Variant

func _init() -> void:
	call_deferred("_run")

func _settle() -> void:
	for index in 5:
		await process_frame

func _run() -> void:
	scene = load("res://Scenes/main.tscn").instantiate()
	scene.set_script(MobileStartup)
	scene.persistent_settings_writes_enabled = false
	scene.session_save_path = "user://mobile_touch_polish_probe.save"
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._stop_background_music()
	scene.mobile_table_layout = true
	scene._apply_mobile_table_layout()
	await _settle()
	assert(scene.round_results_panel.z_index + scene.round_results_countdown_border.z_index < scene.menu_overlay.z_index, "Results border must stay below all menus")
	for locale in ["en", "ru", "uk", "pl", "be", "kz"]:
		TranslationServer.set_locale(locale)
		for page in [scene._show_new_game_setup, scene._show_profile_menu]:
			page.call()
			await _settle()
			scene._fit_menu_panel_to_content()
			await _settle()
			var bar: VScrollBar = scene.menu_scroll.get_v_scroll_bar()
			print("MOBILE_PAGE_FIT ", locale, " ", page.get_method(), " scroll=", bar.max_value - bar.page)
			assert(bar.max_value - bar.page <= 1, "Setup/profile must fit without scrolling")
			assert(not _has_text(scene.menu_content, tr("Музыка профиля")), "Mobile profile must not show music import")
		var preview: Button = scene.menu_content.find_child("MobileProfileAvatarPreview", true, false)
		assert(preview.size.x >= 255 and preview.size.y >= 255)
		assert(scene.profile_avatar_selector.size.x < 600, "Avatar selector must not consume the row")
		preview.pressed.emit()
		await _settle()
		assert(is_instance_valid(scene.mobile_avatar_picker))
		var choice: Button = scene.mobile_avatar_picker.find_child("AvatarChoice2", true, false)
		choice.pressed.emit()
		assert(scene.profile_avatar_selector.selected == 2 and not is_instance_valid(scene.mobile_avatar_picker))
	print("MOBILE_PROFILE_FIT_AVATAR_PASS")
	scene._reset_game_session()
	scene.menu_overlay.hide()
	scene.first_turn_roll_panel.hide()
	scene.stage_announcement_overlay.hide()
	scene.game.current_round.state = Round.State.PLAYING
	scene.game.current_round.current_player_index = 0
	scene.game.current_round.lead_player_index = 0
	scene.game.cards_are_dealt = true
	scene.auto_turn_enabled = false
	for index in 9:
		scene.game.players[0].hand.append(scene._create_card(Card.Suit.CLUBS, Card.Rank.SIX + index, false))
	scene._refresh_hand()
	scene._refresh_player_avatar_badges()
	scene._refresh_sticker_controls()
	await _settle()
	for button in [scene.undo_button, scene.mobile_sort_button, scene.mobile_bid_menu_button]:
		assert(button.size.y >= 64 and button.get_theme_font_size("font_size") >= 28)
		for card in scene.hand_container.get_children():
			assert(not button.get_global_rect().intersects(card.get_global_rect()), "Mobile controls must not overlap nine cards")
	assert(scene.undo_button.get_global_rect().end.y < scene.mobile_sort_button.get_global_rect().position.y)
	print("HINT_ACTION_RECTS ", scene.mobile_premove_hint.get_global_rect(), " ", scene.action_label.get_global_rect())
	assert(scene.mobile_premove_hint.get_global_rect().end.y <= scene.action_label.get_global_rect().position.y)
	assert(scene.sticker_toggle_button.visible)
	scene._on_sticker_toggle_pressed()
	await _settle()
	assert(scene.sticker_picker.visible and scene.sticker_picker.size.y <= 240, "Gift recipient selection must fit its enlarged phone buttons")
	assert(scene.sticker_picker.get_global_rect().end.x < scene.sticker_toggle_button.get_global_rect().position.x)
	assert(scene.get_viewport_rect().encloses(scene.sticker_picker.get_global_rect()))
	scene._on_sticker_target_selected(1)
	await _settle()
	assert(scene.sticker_picker.size.y <= 280, "Gift choices must hug the complete two-row grid")
	assert(scene.get_viewport_rect().encloses(scene.sticker_picker.get_global_rect()))
	var gift_scroll := scene.sticker_picker_content.get_child(0) as ScrollContainer
	var gift_center := gift_scroll.get_child(0) as CenterContainer
	var gift_grid := gift_center.get_child(0) as GridContainer
	assert(gift_grid.columns == 5 and gift_grid.get_child_count() == 10, "All gifts must be visible as a 5x2 phone grid")
	assert(gift_grid.size.y <= 212.0, "Gift grid must not create an empty third row")
	for gift_button: Button in gift_grid.get_children():
		assert(gift_button.size.x >= 110.0 and gift_button.size.y >= 100.0)
	scene._close_sticker_picker()
	for social_button in [scene.reaction_toggle_button, scene.sticker_toggle_button, scene.soundpad_toggle_button]:
		assert(social_button.size.x >= 110 and social_button.size.x <= 114)
		assert(social_button.size.y >= 102 and social_button.size.y <= 106)
		assert(social_button.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER)
		assert(social_button.vertical_icon_alignment == VERTICAL_ALIGNMENT_CENTER)
		assert(social_button.get_global_rect().end.y < scene.mobile_bid_menu_button.get_global_rect().position.y)
	scene._build_soundpad_category_picker()
	scene.soundpad_picker.show()
	await _settle()
	assert(scene.soundpad_picker.size.x <= 600 and scene.soundpad_picker.size.y <= 260, "Soundbar popup must hug its touch choices: %s" % scene.soundpad_picker.size)
	for tapped_category_id in ["root", "custom"]:
		scene._build_soundpad_category_picker()
		scene.soundpad_picker.show()
		await _settle()
		var category_scroll := scene.soundpad_picker.find_child("MobileSoundpadCategoryScroll", true, false) as ScrollContainer
		var category_grid := category_scroll.get_child(0) as GridContainer
		var tapped_button: Button
		for category_button: Button in category_grid.get_children():
			if category_button.text == scene._get_soundpad_category_label(tapped_category_id):
				tapped_button = category_button
				break
		assert(tapped_button != null)
		var category_touch := category_scroll.get_node("SoundpadCategoryTouchScroll")
		var press := InputEventScreenTouch.new()
		press.index = 0
		press.pressed = true
		press.position = tapped_button.get_global_rect().get_center()
		category_touch._input(press)
		var release := InputEventScreenTouch.new()
		release.index = 0
		release.pressed = false
		release.position = press.position
		category_touch._input(release)
		await _settle()
		assert(scene.soundpad_picker.visible, "Tapping a sound category must keep its popup open")
		assert(scene.soundpad_selected_category_id == tapped_category_id, "Tapped %s but selected %s" % [tapped_category_id, scene.soundpad_selected_category_id])
	for category: Dictionary in scene._get_soundpad_categories():
		var category_id := str(category.get("id", "root"))
		var expected_sound_count := 0
		for sound_data: Dictionary in scene.soundpad_sounds:
			if str(sound_data.get("category", "root")) == category_id:
				expected_sound_count += 1
		scene.soundpad_selected_category_id = category_id
		scene._build_soundpad_sound_picker()
		await _settle()
		var sound_grid := scene.soundpad_picker.find_child("SoundpadChoiceGrid", true, false) as GridContainer
		assert(sound_grid != null and sound_grid.get_child_count() == expected_sound_count)
		assert(expected_sound_count > 0, "Visible soundbar categories must never open empty")
		assert(scene.soundpad_picker.get_global_rect().end.x < scene.soundpad_toggle_button.get_global_rect().position.x)
		for sound_button: Button in sound_grid.get_children():
			assert(sound_button.clip_text and sound_button.autowrap_mode == TextServer.AUTOWRAP_OFF)
	scene.soundpad_picker.hide()
	for slot in [1, 2, 3]:
		scene._on_mobile_avatar_pressed(slot)
		await _settle()
		var tray: Control = scene.avatar_action_trays[slot]
		assert(not tray.visible, "Local bots must not expose a fake player profile")
		assert(not scene.avatar_gift_buttons[slot].visible, "Per-player gift shortcut is removed")
	scene._on_mobile_avatar_pressed(0)
	await _settle()
	assert(is_instance_valid(scene.mobile_avatar_picker))
	scene._choose_mobile_avatar(1)
	assert(scene.configured_avatar_indices[0] == 1)
	print("MOBILE_AVATAR_ACTIONS_POSITIONS_PASS")
	var reaction_scroll: ScrollContainer = scene.reaction_picker.get_node("MobileReactionScroll")
	var grid := reaction_scroll.get_child(0) as GridContainer
	assert(grid.columns == 3)
	assert(grid.get_child(0).get_theme_constant("icon_max_width") == 68)
	scene.reaction_picker.show()
	await _settle()
	assert(scene._can_use_mobile_hand_input(), "Social popups must not block card gestures")
	assert(reaction_scroll.get_v_scroll_bar().max_value > reaction_scroll.get_v_scroll_bar().page)
	var sent: Array[int] = []
	for index in grid.get_child_count():
		grid.get_child(index).pressed.connect(func(): sent.append(index))
	var touch_start: Vector2 = reaction_scroll.get_global_rect().position + Vector2(70, 220)
	_touch(touch_start, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = root.get_final_transform() * (touch_start - Vector2(0, 150))
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	_touch(touch_start - Vector2(0, 150), false)
	await _settle()
	assert(reaction_scroll.scroll_vertical > 0 and sent.is_empty() and scene.reaction_picker.visible, "Swipe over choices must scroll without sending")
	for choice in grid.get_children():
		var point: Vector2 = choice.get_global_rect().get_center()
		if reaction_scroll.get_global_rect().has_point(point):
			_touch(point, true)
			_touch(point, false)
			break
	assert(sent.size() == 1 and not scene.reaction_picker.visible, "A short tap sends exactly one reaction")
	print("MOBILE_EMOJI_TOUCH_SCROLL_PASS")
	scene.reaction_picker.hide()
	var sources := GridContainer.new()
	scene.add_child(sources)
	sources.hide()
	var selected: Array[int] = []
	for index in 10:
		var button := Button.new()
		button.text = str(index)
		button.disabled = index == 7
		button.pressed.connect(func(): selected.append(index))
		sources.add_child(button)
	scene.mobile_bid_popup.configure(sources)
	scene.mobile_bid_popup.show()
	await create_timer(0.65).timeout
	assert(scene.mobile_bid_popup.fan_buttons.size() == 10)
	assert(scene.mobile_bid_menu_button.z_index > scene.mobile_bid_popup.z_index, "Bid button must render in front of the fan")
	for index in 10:
		var button: Button = scene.mobile_bid_popup.fan_buttons[index]
		assert(button.disabled == (index == 7))
		assert(not button.get_global_rect().intersects(scene.mobile_bid_menu_button.get_global_rect()), "Fan must leave its open/close button usable")
		assert(not button.get_global_rect().intersects(scene.avatar_badges[3].get_global_rect()), "Fan must stay below the right player")
		assert(Rect2(Vector2.ZERO, scene.CornerBidFanResource.FAN_SIZE).encloses(Rect2(button.position, button.size)))
		for other in range(index + 1, 10):
			var other_button: Button = scene.mobile_bid_popup.fan_buttons[other]
			assert(not Rect2(button.position, button.size).intersects(Rect2(other_button.position, other_button.size)), "Fan choices must not overlap")
	scene.mobile_bid_popup.fan_buttons[9].pressed.emit()
	assert(selected == [9], "Fan action must invoke the original callback")
	scene.mobile_bid_popup.hide()
	sources.queue_free()
	print("MOBILE_EMOJI_BID_FAN_PASS")
	scene.queue_free()
	await process_frame
	print("MOBILE_TOUCH_POLISH_TEST_PASS")
	quit()

func _touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = root.get_final_transform() * point
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _has_text(node: Node, expected: String) -> bool:
	if node is Button and node.text == expected:
		return true
	for child in node.get_children():
		if _has_text(child, expected):
			return true
	return false
