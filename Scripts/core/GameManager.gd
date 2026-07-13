extends Node


const PLAYER_NAMES := ["Андрей", "Олег", "Маша", "Лена"]


var players: Array[Player] = []
var deck := Deck.new()
var current_round := Round.new()


func _ready() -> void:
	_create_players()
	_start_demo_round()


func _create_players() -> void:
	players.clear()

	for player_index in PLAYER_NAMES.size():
		players.append(Player.new(player_index, PLAYER_NAMES[player_index]))


func _start_demo_round() -> void:
	var random := RandomNumberGenerator.new()
	random.randomize()

	var dealer_index := random.randi_range(0, players.size() - 1)
	var cards_per_player := 2

	deck.create_deck()
	deck.shuffle()

	current_round.setup(
		1,
		Round.RoundType.NORMAL,
		cards_per_player,
		Round.TrumpSuit.RANDOM,
		dealer_index,
		players.size()
	)

	_deal_cards(dealer_index, cards_per_player)

	var trump_card := deck.draw()
	current_round.set_trump(Round.trump_from_card(trump_card))


	print("=== Project Joker ===")
	print("Сдающий: %s" % players[dealer_index].display_name)
	print("Открытая карта: %s; козырь: %s" % [trump_card.get_card_name(), current_round.get_trump_name()])

	for player in players:
		print("%s: %s" % [player.display_name, player.get_hand_text()])

	current_round.start_bidding()
	_place_demo_bids()
	_run_trick_rules_demo()


func _deal_cards(dealer_index: int, cards_per_player: int) -> void:
	for player in players:
		player.reset_for_round()

	for card_number in cards_per_player:
		for player_offset in players.size():
			var player_index := (dealer_index + 1 + player_offset) % players.size()
			var card := deck.draw()

			if card == null:
				push_error("Недостаточно карт для раздачи.")
				return

			players[player_index].receive_card(card)

	for player in players:
		player.sort_hand()


func _place_demo_bids() -> void:
	var bids: Array[int] = [1, 0, 0]

	for bid in bids:
		var player_index := current_round.current_player_index
		current_round.place_bid(player_index, bid)
		players[player_index].bid = bid
		print("%s заказывает %d" % [players[player_index].display_name, bid])

	var dealer_bid := 1
	var dealer_index := current_round.current_player_index
	var can_place_forbidden_bid := current_round.can_place_bid(dealer_index, dealer_bid)

	print("%s пытается заказать %d: %s" % [
		players[dealer_index].display_name,
		dealer_bid,
		"разрешено" if can_place_forbidden_bid else "запрещено: сумма заказов равна числу карт"
	])

	current_round.place_bid(dealer_index, 0)
	players[dealer_index].bid = 0
	print("%s заказывает 0" % players[dealer_index].display_name)


func _run_trick_rules_demo() -> void:
	var demo_players: Array[Player] = []

	for player_index in PLAYER_NAMES.size():
		demo_players.append(Player.new(player_index, PLAYER_NAMES[player_index]))

	var spade_ten := _create_card(Card.Suit.SPADES, Card.Rank.TEN)
	var spade_jack := _create_card(Card.Suit.SPADES, Card.Rank.JACK)
	var heart_ace := _create_card(Card.Suit.HEARTS, Card.Rank.ACE)
	var club_six := _create_card(Card.Suit.CLUBS, Card.Rank.SIX)

	demo_players[0].receive_card(spade_ten)
	demo_players[1].receive_card(spade_jack)
	demo_players[2].receive_card(heart_ace)
	demo_players[3].receive_card(club_six)

	var trump_trick := Trick.new()
	trump_trick.setup(0, demo_players.size(), Round.TrumpSuit.HEARTS)
	trump_trick.play_card(demo_players[0], spade_ten)
	trump_trick.play_card(demo_players[1], spade_jack)
	trump_trick.play_card(demo_players[2], heart_ace)
	trump_trick.play_card(demo_players[3], club_six)

	var trump_winner := trump_trick.get_winner_index()
	print("Проверка взятки: ♥ перебивает ♠, взятку забирает %s" % demo_players[trump_winner].display_name)

	var no_trump_players: Array[Player] = []

	for player_index in PLAYER_NAMES.size():
		no_trump_players.append(Player.new(player_index, PLAYER_NAMES[player_index]))

	var diamond_ten := _create_card(Card.Suit.DIAMONDS, Card.Rank.TEN)
	var diamond_six := _create_card(Card.Suit.DIAMONDS, Card.Rank.SIX)
	var joker := _create_card(Card.Suit.CLUBS, Card.Rank.SEVEN, true)
	var diamond_ace := _create_card(Card.Suit.DIAMONDS, Card.Rank.ACE)
	var diamond_king := _create_card(Card.Suit.DIAMONDS, Card.Rank.KING)

	no_trump_players[0].receive_card(diamond_ten)
	no_trump_players[1].receive_card(diamond_six)
	no_trump_players[1].receive_card(joker)
	no_trump_players[2].receive_card(diamond_ace)
	no_trump_players[3].receive_card(diamond_king)

	var no_trump_trick := Trick.new()
	no_trump_trick.setup(0, no_trump_players.size(), Round.TrumpSuit.NONE)
	no_trump_trick.play_card(no_trump_players[0], diamond_ten)
	no_trump_trick.play_card(no_trump_players[1], joker, Trick.JokerMode.JOKER_WINS)
	no_trump_trick.play_card(no_trump_players[2], diamond_ace)
	no_trump_trick.play_card(no_trump_players[3], diamond_king)

	var joker_winner := no_trump_trick.get_winner_index()
	print("Проверка бескозырки: Джокер можно положить вне масти, взятку забирает %s" % no_trump_players[joker_winner].display_name)


func _create_card(suit: Card.Suit, rank: Card.Rank, is_joker := false) -> Card:
	var card := Card.new()
	card.suit = suit
	card.rank = rank
	card.is_joker = is_joker
	return card
