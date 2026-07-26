class_name CardArtwork

extends RefCounted


const JUMBO_INDEX_ROOT := "res://Assets/Cards/JumboIndex/"

static var texture_cache: Dictionary = {}


static func get_face_texture(card: Card) -> Texture2D:
	if card == null:
		return null

	if card.is_joker:
		return _load_texture("redJoker.png")

	var suit_name := _get_suit_name(card.suit)
	var rank_name := _get_rank_name(card.rank)
	if suit_name.is_empty() or rank_name.is_empty():
		return null

	return _load_texture("%s%s.png" % [suit_name, rank_name])


static func get_back_texture() -> Texture2D:
	return _load_texture("blueBack.png")


static func _load_texture(file_name: String) -> Texture2D:
	var texture_path := JUMBO_INDEX_ROOT.path_join(file_name)
	if texture_cache.has(texture_path):
		return texture_cache[texture_path] as Texture2D

	if not ResourceLoader.exists(texture_path):
		return null

	var texture := load(texture_path) as Texture2D
	if texture != null:
		texture_cache[texture_path] = texture
	return texture


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
