class_name BotMonteCarloStrategy

extends RefCounted


# The planner deliberately receives the host Game for convenient access to the
# public table state, but never reads another player's cards. Opponent hands are
# reconstructed from the bot's own hand, the open trump and cards already seen.
const DEFAULT_SIMULATION_COUNT := 180
const MIN_ROLLOUTS_PER_CARD := 18
const MAX_DEAL_ATTEMPTS := 48
const MAX_ROLLOUT_ACTIONS := 48


static func choose_card(
	game: Game,
	player_index: int,
	legal_cards: Array[Card],
	random: RandomNumberGenerator,
	team_mode := false,
	simulation_count := DEFAULT_SIMULATION_COUNT
) -> Card:
	if (
		game == null
		or game.current_round == null
		or player_index < 0
		or player_index >= game.players.size()
		or legal_cards.is_empty()
	):
		return null
	if legal_cards.size() == 1:
		return legal_cards[0]

	var candidate_cards := legal_cards
	if game.current_round.round_type == Round.RoundType.MISERE and game.active_trick == null:
		candidate_cards = _filter_misere_lead_candidates(game, player_index, legal_cards)

	var rollouts_per_card := maxi(
		MIN_ROLLOUTS_PER_CARD,
		ceili(float(maxi(1, simulation_count)) / float(candidate_cards.size()))
	)
	var best_card: Card
	var best_average := -INF
	var best_exact_rate := -1.0

	for candidate in candidate_cards:
		var total_utility := 0.0
		var exact_outcomes := 0
		var completed_rollouts := 0
		for rollout_index in rollouts_per_card:
			var simulation := _create_determinized_game(game, player_index, random)
			if simulation == null:
				continue
			var simulated_candidate := _find_card_by_key(
				simulation.players[player_index].hand,
				_card_key(candidate)
			)
			if simulated_candidate == null or not _play_card_with_policy(simulation, player_index, simulated_candidate):
				continue
			_roll_out_round(simulation, random)
			if not simulation.is_round_complete():
				continue
			completed_rollouts += 1
			total_utility += _evaluate_round(simulation, player_index, team_mode)
			if _actor_hit_target(simulation, player_index):
				exact_outcomes += 1

		if completed_rollouts == 0:
			continue
		var average_utility := total_utility / float(completed_rollouts)
		var exact_rate := float(exact_outcomes) / float(completed_rollouts)
		if (
			best_card == null
			or average_utility > best_average + 0.001
			or (is_equal_approx(average_utility, best_average) and exact_rate > best_exact_rate)
		):
			best_card = candidate
			best_average = average_utility
			best_exact_rate = exact_rate

	return best_card


static func _create_determinized_game(
	source: Game,
	viewer_index: int,
	random: RandomNumberGenerator
) -> Game:
	var player_names: Array[String] = []
	for source_player in source.players:
		player_names.append(source_player.display_name)
	var simulation := Game.new(player_names)
	simulation.dealer_index = source.dealer_index
	simulation.round_number = source.round_number
	simulation.cards_are_dealt = source.cards_are_dealt
	simulation.current_round = _clone_round(source.current_round)
	simulation.active_trick = _clone_trick(source.active_trick)
	simulation.trump_card = source.trump_card
	simulation.played_cards_this_round.assign(source.played_cards_this_round)
	simulation.played_cards_by_this_round.assign(source.played_cards_by_this_round)
	simulation.last_trick_winner_index = source.last_trick_winner_index

	for player_index in simulation.players.size():
		var target := simulation.players[player_index]
		var original := source.players[player_index]
		target.hand.clear()
		target.bid = original.bid
		target.tricks_taken = original.tricks_taken
		target.total_score = original.total_score
		target.exact_orders_completed = original.exact_orders_completed
	if viewer_index < 0 or viewer_index >= simulation.players.size():
		return null
	simulation.players[viewer_index].hand.assign(source.players[viewer_index].hand)

	var unknown_cards := _build_unknown_card_pool(source, viewer_index)
	var sampled_hands := _sample_hidden_hands(source, viewer_index, unknown_cards, random)
	if sampled_hands.is_empty():
		return null
	var assigned_keys: Dictionary = {}
	for player_index in simulation.players.size():
		if player_index == viewer_index:
			continue
		var sampled_hand: Array[Card] = sampled_hands.get(player_index, [])
		simulation.players[player_index].hand.assign(sampled_hand)
		for card in sampled_hand:
			assigned_keys[_card_key(card)] = true

	simulation.deck.cards.clear()
	for card in unknown_cards:
		if not assigned_keys.has(_card_key(card)):
			simulation.deck.cards.append(card)
	return simulation


static func _build_unknown_card_pool(game: Game, viewer_index: int) -> Array[Card]:
	var known_keys: Dictionary = {}
	for card in game.players[viewer_index].hand:
		known_keys[_card_key(card)] = true
	for card in game.played_cards_this_round:
		known_keys[_card_key(card)] = true
	if game.trump_card != null:
		known_keys[_card_key(game.trump_card)] = true

	var deck := Deck.new()
	deck.create_deck()
	var unknown_cards: Array[Card] = []
	for card in deck.cards:
		if not known_keys.has(_card_key(card)):
			unknown_cards.append(card)
	return unknown_cards


static func _sample_hidden_hands(
	game: Game,
	viewer_index: int,
	unknown_cards: Array[Card],
	random: RandomNumberGenerator
) -> Dictionary:
	var void_suits := _infer_public_void_suits(game)
	var hidden_player_indices: Array[int] = []
	for player_index in game.players.size():
		if player_index != viewer_index:
			hidden_player_indices.append(player_index)
	# Deal the most constrained opponents first. This makes a valid public-world
	# reconstruction much more likely without ever contradicting a shown void.
	hidden_player_indices.sort_custom(func(left: int, right: int) -> bool:
		var left_voids: Dictionary = void_suits.get(left, {})
		var right_voids: Dictionary = void_suits.get(right, {})
		if left_voids.size() == right_voids.size():
			return game.players[left].hand.size() > game.players[right].hand.size()
		return left_voids.size() > right_voids.size()
	)
	for attempt in MAX_DEAL_ATTEMPTS:
		var available := unknown_cards.duplicate()
		_shuffle_cards(available, random)
		var sampled_hands: Dictionary = {}
		var deal_is_valid := true
		for player_index in hidden_player_indices:
			var hand: Array[Card] = []
			var needed := game.players[player_index].hand.size()
			var eligible: Array[Card] = []
			var player_voids: Dictionary = void_suits.get(player_index, {})
			for card in available:
				if not _violates_void_knowledge(card, player_voids):
					eligible.append(card)
			if eligible.size() < needed:
				deal_is_valid = false
				break
			_shuffle_cards(eligible, random)
			for card_offset in needed:
				var card: Card = eligible[card_offset]
				hand.append(card)
				available.erase(card)
			sampled_hands[player_index] = hand
		if deal_is_valid:
			return sampled_hands

	# An impossible public world is safer than a fabricated one that gives cards
	# of a suit to a player who has already publicly shown that suit is absent.
	# The caller will use the deterministic hard-bot fallback for this decision.
	return {}


static func _infer_public_void_suits(game: Game) -> Dictionary:
	var result: Dictionary = {}
	var player_count := game.players.size()
	if player_count <= 0:
		return result
	var active_start := (
		game.played_cards_this_round.size() - game.active_trick.played_cards.size()
		if game.active_trick != null
		else game.played_cards_this_round.size()
	)
	var lead_suit := -1
	for card_index in game.played_cards_this_round.size():
		var position := card_index % player_count
		var card: Card = game.played_cards_this_round[card_index]
		if position == 0:
			lead_suit = (
				game.active_trick.lead_suit
				if game.active_trick != null and card_index >= active_start
				else (-1 if card.is_joker else card.suit)
			)
			continue
		if card.is_joker or lead_suit < 0:
			continue
		if card_index >= game.played_cards_by_this_round.size():
			# Older diagnostic saves and a few isolated rule probes may contain
			# cards without their public player-index companion.
			continue
		var player_index := int(game.played_cards_by_this_round[card_index])
		if card.suit == lead_suit:
			continue
		_mark_void_suit(result, player_index, lead_suit)
		if (
			game.current_round.trump != Round.TrumpSuit.NONE
			and game.current_round.trump != Round.TrumpSuit.RANDOM
			and card.suit != game.current_round.trump
		):
			_mark_void_suit(result, player_index, game.current_round.trump)
	return result


static func _mark_void_suit(void_suits: Dictionary, player_index: int, suit: int) -> void:
	var player_voids: Dictionary = void_suits.get(player_index, {})
	player_voids[suit] = true
	void_suits[player_index] = player_voids


static func _violates_void_knowledge(card: Card, player_voids: Dictionary) -> bool:
	return not card.is_joker and player_voids.has(card.suit)


static func _filter_misere_lead_candidates(
	game: Game,
	player_index: int,
	legal_cards: Array[Card]
) -> Array[Card]:
	var regular_cards := _regular_cards(legal_cards)
	if regular_cards.is_empty():
		return legal_cards
	var void_suits := _infer_public_void_suits(game)
	var safe_suits: Array[Card] = []
	for card in regular_cards:
		if not _another_player_is_known_void(game, player_index, card.suit, void_suits):
			safe_suits.append(card)
	var candidates := safe_suits if not safe_suits.is_empty() else regular_cards

	# On misere an Ace, or another already unbeatable card, is a poor lead while
	# a card that somebody can still cover is available. This also avoids the
	# conspicuous "take with Ace, then lead a dead Six" sequence.
	var coverable: Array[Card] = []
	for card in candidates:
		if _has_publicly_possible_higher_card(game, player_index, card, void_suits):
			coverable.append(card)
	return coverable if not coverable.is_empty() else candidates


static func _another_player_is_known_void(
	game: Game,
	player_index: int,
	suit: int,
	void_suits: Dictionary
) -> bool:
	for other_index in game.players.size():
		if other_index == player_index or game.players[other_index].hand.is_empty():
			continue
		var other_voids: Dictionary = void_suits.get(other_index, {})
		if other_voids.has(suit):
			return true
	return false


static func _has_publicly_possible_higher_card(
	game: Game,
	player_index: int,
	card: Card,
	void_suits: Dictionary
) -> bool:
	if card.is_joker:
		return false
	var possible_receiver := false
	for other_index in game.players.size():
		if other_index == player_index or game.players[other_index].hand.is_empty():
			continue
		var other_voids: Dictionary = void_suits.get(other_index, {})
		if not other_voids.has(card.suit):
			possible_receiver = true
			break
	if not possible_receiver:
		return false

	var known_keys: Dictionary = {}
	for known_card in game.players[player_index].hand:
		known_keys[_card_key(known_card)] = true
	for known_card in game.played_cards_this_round:
		known_keys[_card_key(known_card)] = true
	if game.trump_card != null:
		known_keys[_card_key(game.trump_card)] = true
	var deck := Deck.new()
	deck.create_deck()
	for unknown_card in deck.cards:
		if (
			not unknown_card.is_joker
			and unknown_card.suit == card.suit
			and unknown_card.rank > card.rank
			and not known_keys.has(_card_key(unknown_card))
		):
			return true
	return false


static func _roll_out_round(game: Game, random: RandomNumberGenerator) -> void:
	var action_count := 0
	while not game.is_round_complete() and action_count < MAX_ROLLOUT_ACTIONS:
		action_count += 1
		var player_index := _get_current_player_index(game)
		if player_index < 0 or player_index >= game.players.size():
			return
		var player := game.players[player_index]
		var legal_cards := _get_legal_cards(game, player)
		if legal_cards.is_empty():
			return
		var selected := _choose_rollout_card(game, player, legal_cards, random)
		if selected == null or not _play_card_with_policy(game, player_index, selected):
			return


static func _choose_rollout_card(
	game: Game,
	player: Player,
	legal_cards: Array[Card],
	random: RandomNumberGenerator
) -> Card:
	if legal_cards.size() == 1:
		return legal_cards[0]
	var wants_trick := _wants_trick(game.current_round.round_type, player)
	if game.active_trick == null:
		var regular_leads := _regular_cards(legal_cards)
		if regular_leads.is_empty():
			return legal_cards[0]
		if game.current_round.round_type == Round.RoundType.MISERE:
			var player_index := game.players.find(player)
			regular_leads = _filter_misere_lead_candidates(game, player_index, regular_leads)
		return _select_by_strength(game, regular_leads, wants_trick)

	var winners: Array[Card] = []
	var losers: Array[Card] = []
	var joker: Card
	for card in legal_cards:
		if card.is_joker:
			joker = card
		elif _would_win_now(game, card):
			winners.append(card)
		else:
			losers.append(card)
	if wants_trick:
		if not winners.is_empty():
			return _select_by_strength(game, winners, false)
		if joker != null:
			return joker
		return _select_by_strength(game, losers, false)
	if not losers.is_empty():
		return _select_by_strength(game, losers, true)
	if joker != null:
		return joker
	# A tiny random tie break keeps equally valued sampled worlds from following
	# one fixed suit forever while preserving the avoid/take policy above.
	var weakest := _select_by_strength(game, winners, false)
	return weakest if weakest != null else legal_cards[random.randi_range(0, legal_cards.size() - 1)]


static func _play_card_with_policy(game: Game, player_index: int, card: Card) -> bool:
	if not card.is_joker:
		return game.play_card(player_index, card)
	var player := game.players[player_index]
	var wants_trick := _wants_trick(game.current_round.round_type, player)
	var joker_mode := Trick.JokerMode.JOKER_WINS if wants_trick else Trick.JokerMode.NORMAL_CARD_WINS
	var declared_suit := -1
	if game.active_trick == null:
		declared_suit = _choose_joker_suit(player, not wants_trick)
	return game.play_card(player_index, card, joker_mode, declared_suit)


static func _evaluate_round(game: Game, actor_index: int, team_mode: bool) -> float:
	var round_type := game.current_round.round_type
	var participant_indices: Array[int] = [actor_index]
	if team_mode and game.players.size() == 4:
		participant_indices.append((actor_index + 2) % 4)
	var utility := 0.0
	for player_index in participant_indices:
		var player := game.players[player_index]
		var round_score := ScoreCalculator.calculate_round_score(round_type, player.bid, player.tricks_taken)
		utility += float(round_score) * 10.0
		if ScoreCalculator.is_exact_order(round_type, player.bid, player.tricks_taken):
			utility += 35.0
		elif round_type == Round.RoundType.NORMAL or round_type == Round.RoundType.DARK or round_type == Round.RoundType.NO_TRUMP:
			utility -= float(absi(player.tricks_taken - player.bid)) * 3.0
	return utility


static func _actor_hit_target(game: Game, actor_index: int) -> bool:
	var player := game.players[actor_index]
	match game.current_round.round_type:
		Round.RoundType.GOLDEN:
			return player.tricks_taken > 0
		Round.RoundType.MISERE:
			return player.tricks_taken == 0
	return player.bid >= 0 and player.tricks_taken == player.bid


static func _wants_trick(round_type: Round.RoundType, player: Player) -> bool:
	if round_type == Round.RoundType.GOLDEN:
		return true
	if round_type == Round.RoundType.MISERE:
		return false
	return player.bid != player.tricks_taken


static func _get_current_player_index(game: Game) -> int:
	if game.current_round.state == Round.State.BIDDING:
		return game.current_round.current_player_index
	if game.current_round.state != Round.State.PLAYING:
		return -1
	return game.current_round.lead_player_index if game.active_trick == null else game.active_trick.current_player_index


static func _get_legal_cards(game: Game, player: Player) -> Array[Card]:
	var legal_cards: Array[Card] = []
	for card in player.hand:
		if game.active_trick == null or game.active_trick.can_play_card(player, card):
			legal_cards.append(card)
	return legal_cards


static func _would_win_now(game: Game, card: Card) -> bool:
	if card.is_joker or game.active_trick == null:
		return false
	var simulated := _clone_trick(game.active_trick)
	simulated.player_count = simulated.played_cards.size() + 1
	simulated.played_cards.append(card)
	simulated.played_by.append(-1)
	return simulated.get_winner_index() == -1


static func _select_by_strength(game: Game, cards: Array[Card], choose_highest: bool) -> Card:
	var selected: Card
	for card in cards:
		if selected == null:
			selected = card
			continue
		var strength := _card_strength(game, card)
		var selected_strength := _card_strength(game, selected)
		if strength > selected_strength if choose_highest else strength < selected_strength:
			selected = card
	return selected


static func _card_strength(game: Game, card: Card) -> int:
	if card.is_joker:
		return 100
	var strength := int(card.rank)
	if game.current_round.trump != Round.TrumpSuit.NONE and card.suit == game.current_round.trump:
		strength += 20
	if game.active_trick != null and card.suit == game.active_trick.lead_suit:
		strength += 10
	return strength


static func _regular_cards(cards: Array[Card]) -> Array[Card]:
	var result: Array[Card] = []
	for card in cards:
		if not card.is_joker:
			result.append(card)
	return result


static func _choose_joker_suit(player: Player, prefer_rare_suit: bool) -> int:
	var suit_counts: Array[int] = [0, 0, 0, 0]
	for card in player.hand:
		if not card.is_joker:
			suit_counts[card.suit] += 1
	var selected_suit := Card.Suit.CLUBS
	for suit in Card.Suit.values():
		if prefer_rare_suit and suit_counts[suit] < suit_counts[selected_suit]:
			selected_suit = suit
		elif not prefer_rare_suit and suit_counts[suit] > suit_counts[selected_suit]:
			selected_suit = suit
	return selected_suit


static func _clone_round(source: Round) -> Round:
	var result := Round.new()
	result.number = source.number
	result.cards_per_player = source.cards_per_player
	result.round_type = source.round_type
	result.trump = source.trump
	result.dealer_index = source.dealer_index
	result.player_count = source.player_count
	result.current_player_index = source.current_player_index
	result.lead_player_index = source.lead_player_index
	result.bids.assign(source.bids)
	result.bids_made = source.bids_made
	result.tricks_played = source.tricks_played
	result.state = source.state
	return result


static func _clone_trick(source: Trick) -> Trick:
	if source == null:
		return null
	var result := Trick.new()
	result.player_count = source.player_count
	result.trump = source.trump
	result.leader_index = source.leader_index
	result.current_player_index = source.current_player_index
	result.lead_suit = source.lead_suit
	result.joker_mode = source.joker_mode
	result.declared_suit = source.declared_suit
	result.forced_card_rank = source.forced_card_rank
	result.played_cards.assign(source.played_cards)
	result.played_by.assign(source.played_by)
	return result


static func _find_card_by_key(cards: Array[Card], key: String) -> Card:
	for card in cards:
		if _card_key(card) == key:
			return card
	return null


static func _card_key(card: Card) -> String:
	return "joker" if card.is_joker else "%d_%d" % [card.suit, card.rank]


static func _shuffle_cards(cards: Array, random: RandomNumberGenerator) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var temporary: Variant = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temporary
