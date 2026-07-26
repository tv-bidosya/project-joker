class_name CardArtwork

extends RefCounted


enum DeckStyle {
	JUMBO_FOUR_COLOR,
	CLASSIC_FOUR_COLOR,
	COMPACT_FOUR_COLOR,
	ORIGINAL_JUMBO,
	SIMPLE_FIRST_VERSION,
	VECTOR_CLASSIC
}


const JUMBO_INDEX_ROOT := "res://Assets/Cards/JumboIndex/"
const CLASSIC_FOUR_COLOR_ROOT := "res://Assets/Cards/ClassicFourColor/"
const COMPACT_FOUR_COLOR_ROOT := "res://Assets/Cards/CompactFourColor/"
const VECTOR_CLASSIC_ROOT := "res://Assets/Cards/VectorClassic/"
const DEFAULT_DECK_STYLE := DeckStyle.VECTOR_CLASSIC

static var selected_deck_style: DeckStyle = DEFAULT_DECK_STYLE
static var texture_cache: Dictionary = {}


static func set_deck_style(deck_style: int) -> void:
	selected_deck_style = clampi(deck_style, DeckStyle.JUMBO_FOUR_COLOR, DeckStyle.VECTOR_CLASSIC)


static func get_face_texture(card: Card) -> Texture2D:
	if card == null:
		return null

	if selected_deck_style == DeckStyle.SIMPLE_FIRST_VERSION:
		return null

	if card.is_joker:
		if selected_deck_style == DeckStyle.VECTOR_CLASSIC:
			return _load_texture(VECTOR_CLASSIC_ROOT.path_join("project_joker.png"))
		return _load_texture(JUMBO_INDEX_ROOT.path_join("redJoker.png"))

	match selected_deck_style:
		DeckStyle.CLASSIC_FOUR_COLOR:
			return _load_texture(CLASSIC_FOUR_COLOR_ROOT.path_join(_get_classic_four_color_file_name(card)))
		DeckStyle.COMPACT_FOUR_COLOR:
			return _load_texture(COMPACT_FOUR_COLOR_ROOT.path_join(_get_compact_four_color_file_name(card)))
		DeckStyle.VECTOR_CLASSIC:
			return _load_texture(VECTOR_CLASSIC_ROOT.path_join(_get_vector_classic_file_name(card)))

	var suit_name := _get_suit_name(card.suit)
	var rank_name := _get_rank_name(card.rank)
	if suit_name.is_empty() or rank_name.is_empty():
		return null

	var texture_path := JUMBO_INDEX_ROOT.path_join("%s%s.png" % [suit_name, rank_name])
	if selected_deck_style == DeckStyle.ORIGINAL_JUMBO:
		return _load_texture(texture_path)
	var recolored_cache_path := "%s#four-color" % texture_path
	if texture_cache.has(recolored_cache_path):
		return texture_cache[recolored_cache_path] as Texture2D
	var source_texture := _load_texture(texture_path)
	if (
		source_texture == null
		or (card.suit != Card.Suit.CLUBS and card.suit != Card.Suit.DIAMONDS)
	):
		return source_texture
	var recolored_texture := _create_four_color_texture(source_texture, card.suit)
	if recolored_texture != null:
		texture_cache[recolored_cache_path] = recolored_texture
		return recolored_texture
	return source_texture


static func get_back_texture() -> Texture2D:
	if selected_deck_style == DeckStyle.SIMPLE_FIRST_VERSION:
		return null
	return _load_texture(JUMBO_INDEX_ROOT.path_join("blueBack.png"))


static func _load_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null
	if texture_cache.has(texture_path):
		return texture_cache[texture_path] as Texture2D

	if not ResourceLoader.exists(texture_path):
		return null

	var texture := load(texture_path) as Texture2D
	if texture != null:
		texture_cache[texture_path] = texture
	return texture


static func _get_classic_four_color_file_name(card: Card) -> String:
	var rank_code := ""
	match card.rank:
		Card.Rank.SIX:
			rank_code = "6"
		Card.Rank.SEVEN:
			rank_code = "7"
		Card.Rank.EIGHT:
			rank_code = "8"
		Card.Rank.NINE:
			rank_code = "9"
		Card.Rank.TEN:
			rank_code = "T"
		Card.Rank.JACK:
			rank_code = "J"
		Card.Rank.QUEEN:
			rank_code = "Q"
		Card.Rank.KING:
			rank_code = "K"
		Card.Rank.ACE:
			rank_code = "A"
	var suit_code: String = {
		Card.Suit.CLUBS: "c",
		Card.Suit.SPADES: "s",
		Card.Suit.HEARTS: "h",
		Card.Suit.DIAMONDS: "d"
	}.get(card.suit, "")
	return "%s%s.svg" % [rank_code, suit_code] if not rank_code.is_empty() and not suit_code.is_empty() else ""


static func _get_compact_four_color_file_name(card: Card) -> String:
	var suit_offset: int = {
		Card.Suit.CLUBS: 0,
		Card.Suit.DIAMONDS: 13,
		Card.Suit.HEARTS: 26,
		Card.Suit.SPADES: 39
	}.get(card.suit, -1)
	var rank_offset: int = {
		Card.Rank.ACE: 1,
		Card.Rank.SIX: 6,
		Card.Rank.SEVEN: 7,
		Card.Rank.EIGHT: 8,
		Card.Rank.NINE: 9,
		Card.Rank.TEN: 10,
		Card.Rank.JACK: 11,
		Card.Rank.QUEEN: 12,
		Card.Rank.KING: 13
	}.get(card.rank, -1)
	if suit_offset < 0 or rank_offset < 0:
		return ""
	return "card%d.png" % (suit_offset + rank_offset)


static func _get_vector_classic_file_name(card: Card) -> String:
	var rank_name := ""
	match card.rank:
		Card.Rank.SIX:
			rank_name = "6"
		Card.Rank.SEVEN:
			rank_name = "7"
		Card.Rank.EIGHT:
			rank_name = "8"
		Card.Rank.NINE:
			rank_name = "9"
		Card.Rank.TEN:
			rank_name = "10"
		Card.Rank.JACK:
			rank_name = "jack"
		Card.Rank.QUEEN:
			rank_name = "queen"
		Card.Rank.KING:
			rank_name = "king"
		Card.Rank.ACE:
			rank_name = "ace"
	var suit_name: String = {
		Card.Suit.CLUBS: "clubs",
		Card.Suit.SPADES: "spades",
		Card.Suit.HEARTS: "hearts",
		Card.Suit.DIAMONDS: "diamonds"
	}.get(card.suit, "")
	if rank_name.is_empty() or suit_name.is_empty():
		return ""
	var variant_suffix := "2" if card.rank in [Card.Rank.JACK, Card.Rank.QUEEN, Card.Rank.KING] or (card.rank == Card.Rank.ACE and card.suit == Card.Suit.SPADES) else ""
	return "%s_of_%s%s.png" % [rank_name, suit_name, variant_suffix]


static func _create_four_color_texture(source_texture: Texture2D, suit: Card.Suit) -> Texture2D:
	var source_image := source_texture.get_image()
	if source_image == null or source_image.is_empty():
		return null
	var image := Image.create_from_data(
		source_image.get_width(),
		source_image.get_height(),
		source_image.has_mipmaps(),
		source_image.get_format(),
		source_image.get_data().duplicate()
	)
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if suit == Card.Suit.CLUBS:
				var darkest_channel := maxf(color.r, maxf(color.g, color.b))
				if darkest_channel < 0.48:
					var luminance := color.get_luminance()
					color = Color(0.04 + luminance * 0.18, 0.38 + luminance * 0.42, 0.12 + luminance * 0.2, color.a)
			elif suit == Card.Suit.DIAMONDS and color.r > 0.34 and color.r > color.g * 1.3 and color.r > color.b * 1.3:
				var intensity := color.r
				color = Color(0.05 + intensity * 0.12, 0.2 + intensity * 0.3, 0.55 + intensity * 0.4, color.a)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func _get_suit_name(suit: Card.Suit) -> String:
	match suit:
		Card.Suit.CLUBS:
			return "club"
		Card.Suit.SPADES:
			return "spade"
		Card.Suit.HEARTS:
			return "heart"
		Card.Suit.DIAMONDS:
			return "diamond"

	return ""


static func _get_rank_name(rank: Card.Rank) -> String:
	match rank:
		Card.Rank.SIX:
			return "6"
		Card.Rank.SEVEN:
			return "7"
		Card.Rank.EIGHT:
			return "8"
		Card.Rank.NINE:
			return "9"
		Card.Rank.TEN:
			return "10"
		Card.Rank.JACK:
			return "Jack"
		Card.Rank.QUEEN:
			return "Queen"
		Card.Rank.KING:
			return "King"
		Card.Rank.ACE:
			return "Ace"

	return ""
