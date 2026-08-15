class_name MenuUiTheme
extends RefCounted


enum Style {
	CLASSIC_EMERALD,
	NIGHT_CITY_BLUE,
}

const STYLE_NAMES := ["Классический изумруд", "Ночной город · синий"]
const FORUM_FONT: FontFile = preload("res://Assets/Fonts/Forum-Regular.ttf")
const VOLLKORN_FONT: FontFile = preload("res://Assets/Fonts/Vollkorn-Variable.ttf")
const MANROPE_FONT: FontFile = preload("res://Assets/Fonts/Manrope-Variable.ttf")


static func heading_font() -> Font:
	return FORUM_FONT


static func body_font() -> Font:
	return _weighted_font(MANROPE_FONT, 500)


static func button_font(style: int) -> Font:
	return _weighted_font(
		MANROPE_FONT if style == Style.NIGHT_CITY_BLUE else VOLLKORN_FONT,
		600
	)


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


static func _weighted_font(base_font: Font, weight: int) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = base_font
	variation.variation_opentype = {&"wght": weight}
	if base_font == MANROPE_FONT:
		# Manrope lacks several Kazakh Cyrillic glyphs. Vollkorn covers them and
		# keeps every supported interface language readable without OS fonts.
		variation.fallbacks = [VOLLKORN_FONT]
	return variation
