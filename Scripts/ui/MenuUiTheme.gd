class_name MenuUiTheme
extends RefCounted


enum Style {
	CLASSIC_EMERALD,
	NIGHT_CITY_BLUE,
}

const STYLE_NAMES := ["Классический изумруд", "Ночной город · синий"]
const ARSENAL_BOLD_FONT: FontFile = preload("res://Assets/Fonts/Arsenal-Bold.ttf")
const FIXEL_DISPLAY_SEMIBOLD_FONT: FontFile = preload("res://Assets/Fonts/FixelDisplay-SemiBold.ttf")
const FIXEL_TEXT_MEDIUM_FONT: FontFile = preload("res://Assets/Fonts/FixelText-Medium.ttf")
const VOLLKORN_FONT: FontFile = preload("res://Assets/Fonts/Vollkorn-Variable.ttf")
const BEVELED_EMERALD_TEXTURE: Texture2D = preload("res://Assets/UI/menu_button_beveled_emerald.svg")
const BEVELED_EMERALD_HOVER_TEXTURE: Texture2D = preload("res://Assets/UI/menu_button_beveled_emerald_hover.svg")
const BEVELED_BLUE_TEXTURE: Texture2D = preload("res://Assets/UI/menu_button_beveled_blue.svg")
const BEVELED_BLUE_HOVER_TEXTURE: Texture2D = preload("res://Assets/UI/menu_button_beveled_blue_hover.svg")


static func heading_font() -> Font:
	return _font_with_fallback(ARSENAL_BOLD_FONT)


static func body_font() -> Font:
	return _font_with_fallback(FIXEL_TEXT_MEDIUM_FONT)


static func button_font(style: int) -> Font:
	return _font_with_fallback(FIXEL_DISPLAY_SEMIBOLD_FONT)


static func beveled_button_style(style: int, state: StringName, is_primary := false) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	var use_hover_texture := state == &"hover" or state == &"focus"
	if style == Style.NIGHT_CITY_BLUE:
		result.texture = BEVELED_BLUE_HOVER_TEXTURE if use_hover_texture else BEVELED_BLUE_TEXTURE
	else:
		result.texture = BEVELED_EMERALD_HOVER_TEXTURE if use_hover_texture else BEVELED_EMERALD_TEXTURE
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		result.set_texture_margin(side, 30.0)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		result.set_texture_margin(side, 12.0)
	result.content_margin_left = 30.0
	result.content_margin_right = 30.0
	result.content_margin_top = 8.0
	result.content_margin_bottom = 10.0
	if state == &"pressed":
		result.modulate_color = Color(0.78, 0.8, 0.82, 1.0)
	elif state == &"disabled":
		result.modulate_color = Color(0.48, 0.5, 0.5, 0.7)
	elif is_primary and state == &"normal":
		result.modulate_color = Color(1.08, 1.06, 0.98, 1.0)
	return result


static func palette(style: int) -> Dictionary:
	if style == Style.NIGHT_CITY_BLUE:
		return {
			&"backdrop": Color("07101f"),
			&"panel": Color("0a1424"),
			&"panel_deep": Color("07111f"),
			&"field": Color("0d192c"),
			&"button": Color("182a50"),
			&"button_primary": Color("203969"),
			&"button_hover": Color("274477"),
			&"button_pressed": Color("142541"),
			&"border": Color("8b6a32"),
			&"border_bright": Color("d8bb75"),
			&"heading": Color("d8bb75"),
			&"text": Color("f0e8d6"),
			&"button_text": Color("f0e8d6"),
			&"secondary": Color("a8b3c7"),
			&"disabled": Color("687489"),
			&"hover": Color("6f91d8"),
			&"glow": Color("90adf0"),
		}
	return {
		&"backdrop": Color("02150e"),
		&"panel": Color("082218"),
		&"panel_deep": Color("03150f"),
		&"field": Color("071a13"),
		&"button": Color("09251a"),
		&"button_primary": Color("103326"),
		&"button_hover": Color("173d30"),
		&"button_pressed": Color("0a2018"),
		&"border": Color("b1782c"),
		&"border_bright": Color("d5a44a"),
		&"heading": Color("e6c778"),
		&"text": Color("eee5ce"),
		&"button_text": Color("f3e5ba"),
		&"secondary": Color("9eaea0"),
		&"disabled": Color("6f796f"),
		&"hover": Color("3f8066"),
		&"glow": Color("f1ce73"),
	}


static func _font_with_fallback(base_font: Font) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = base_font
	# Fixel and Arsenal cover the full Ukrainian alphabet. Vollkorn remains a
	# bundled fallback for Kazakh Cyrillic and any rarer glyphs in translations.
	variation.fallbacks = [VOLLKORN_FONT]
	return variation
