class_name BotMonteCarloStrategy

extends RefCounted


# The planner deliberately receives the host Game for convenient access to the
# public table state, but never reads another player's cards. Opponent hands are
# reconstructed from the bot's own hand, the open trump and cards already seen.
const DEFAULT_SIMULATION_COUNT := 480
const MIN_ROLLOUTS_PER_CARD := 32
const BID_SIMULATION_COUNT := 360
const MAX_PLANNING_MSEC := 1000
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

	var candidate_cards := _filter_candidates(game, player_index, legal_cards, team_mode)
	var rollouts_per_card := maxi(
		MIN_ROLLOUTS_PER_CARD,
		ceili(float(maxi(1, simulation_count)) / float(candidate_cards.size()))
	)
	var totals: Array[float] = []
	var counts: Array[int] = []
	totals.resize(candidate_cards.size())
	counts.resize(candidate_cards.size())
	var started_at := Time.get_ticks_msec()
	# Compare ALL candidates against the SAME sampled world and rollout seed.
	# Independent deals per candidate previously let sampling noise reward an
	# otherwise pointless ace discard or duck in a golden round.
	for rollout_index in rollouts_per_card:
		var simulation := _create_determinized_game(game, player_index, random)
		if simulation == null:
			continue
		var initial_state := simulation.create_snapshot()
		var rollout_seed := random.randi()
		for candidate_index in candidate_cards.size():
			simulation.restore_snapshot(initial_state)
			var candidate: Card = candidate_cards[candidate_index]
			var rollout_random := RandomNumberGenerator.new()
			rollout_random.seed = rollout_seed
			var simulated_candidate := _find_card_by_key(
				simulation.players[player_index].hand,
				_card_key(candidate)
			)
			if simulated_candidate == null or not _play_card_with_policy(simulation, player_index, simulated_candidate, team_mode):
				continue
			_roll_out_round(simulation, rollout_random, team_mode)
			if not simulation.is_round_complete():
				continue
			counts[candidate_index] += 1
			totals[candidate_index] += _evaluate_round(simulation, player_index, team_mode)
		if rollout_index >= MIN_ROLLOUTS_PER_CARD - 1 and Time.get_ticks_msec() - started_at >= MAX_PLANNING_MSEC:
			break

	var best_card: Card
	var best_average := -INF
	for index in candidate_cards.size():
		if counts[index] == 0:
			continue
		var candidate: Card = candidate_cards[index]
		var average := totals[index] / float(counts[index])
		# Only breaks practically equal outcomes; cannot outweigh a score point.
		average += _card_tie_break(game, player_index, candidate, team_mode)
		if best_card == null or average > best_average:
			best_card = candidate
			best_average = average
	return best_card


static func choose_bid(game: Game, player_index: int, random: RandomNumberGenerator, team_mode := false, simulation_count := BID_SIMULATION_COUNT) -> int:
	if game == null or game.current_round == null or player_index < 0 or player_index >= game.players.size():
		return -1
	if game.current_round.state != Round.State.BIDDING or game.current_round.round_type == Round.RoundType.DARK or not game.cards_are_dealt:
		return -1
	var valid_bids: Array[int] = []
	for bid in range(game.current_round.cards_per_player + 1):
		if game.current_round.can_place_bid(player_index, bid):
			valid_bids.append(bid)
	if valid_bids.is_empty():
		return -1
	var totals: Array[float] = []
	totals.resize(valid_bids.size())
	var samples := 0
	var started_at := Time.get_ticks_msec()
	var world_count := maxi(MIN_ROLLOUTS_PER_CARD, ceili(float(simulation_count) / valid_bids.size()))
	for world_index in world_count:
		var simulation := _create_determinized_game(game, player_index, random)
		if simulation == null:
			continue
		var initial_state := simulation.create_snapshot()
		var rollout_seed := random.randi()
		for bid_index in valid_bids.size():
			simulation.restore_snapshot(initial_state)
			if not simulation.place_bid(player_index, valid_bids[bid_index]):
				return -1
			# Unknown future orders use only each sampled player's own hand. Orders
			# already made are preserved, including the partner's target.
			while simulation.current_round.state == Round.State.BIDDING:
				var bidder := simulation.current_round.current_player_index
				var estimate := estimate_hand_bid(simulation.players[bidder], simulation.current_round)
				var chosen := -1
				for bid in range(simulation.current_round.cards_per_player + 1):
					if simulation.current_round.can_place_bid(bidder, bid) and (chosen < 0 or absi(bid - estimate) < absi(chosen - estimate)):
						chosen = bid
				if chosen < 0 or not simulation.place_bid(bidder, chosen):
					return -1
			var rollout_random := RandomNumberGenerator.new()
			rollout_random.seed = rollout_seed
			_roll_out_round(simulation, rollout_random, team_mode)
			if not simulation.is_round_complete():
				return -1
			totals[bid_index] += _evaluate_round(simulation, player_index, team_mode)
		samples += 1
		if samples >= MIN_ROLLOUTS_PER_CARD and Time.get_ticks_msec() - started_at >= MAX_PLANNING_MSEC:
			break
	if samples == 0:
		return -1
	var best_index := 0
	for index in range(1, totals.size()):
		if totals[index] > totals[best_index]:
			best_index = index
	return valid_bids[best_index]


static func estimate_hand_bid(player: Player, round: Round) -> int:
	var estimate := 0.0
	for card in player.hand:
		if card.is_joker:
			estimate += 1.0
			continue
		var missing_higher := int(Card.Rank.ACE) - int(card.rank)
		if card.suit == Card.Suit.CLUBS and card.rank < Card.Rank.SEVEN:
			missing_higher -= 1 # 7 clubs is the Joker, not a regular club.
		var suit_length := 0
		for held in player.hand:
			if not held.is_joker and held.suit == card.suit:
				suit_length += 1
				if held.rank > card.rank:
					missing_higher -= 1
		var is_trump := card.suit == round.trump
		if missing_higher == 0:
			estimate += 0.95 if is_trump or round.trump == Round.TrumpSuit.NONE else 0.8
		elif missing_higher == 1:
			estimate += 0.65 if is_trump or suit_length >= 2 else 0.35
		elif missing_higher == 2:
			estimate += 0.4 if is_trump or suit_length >= 3 else 0.15
		elif is_trump:
			estimate += 0.25
	return clampi(roundi(estimate), 0, round.cards_per_player)


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
	simulation.played_lead_suits_this_round.assign(source.played_lead_suits_this_round)
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
	var played_count := mini(game.played_cards_this_round.size(), game.played_cards_by_this_round.size())
	# A trick starts wherever the recorded player sequence starts, not at a
	# fixed modulo position: its leader is the previous trick's winner.
	var trick_start := 0
	while trick_start < played_count:
		var trick_size := mini(player_count, played_count - trick_start)
		var lead_card: Card = game.played_cards_this_round[trick_start]
		var lead_suit := -1
		if trick_start < game.played_lead_suits_this_round.size() and game.played_lead_suits_this_round[trick_start] >= 0:
			lead_suit = game.played_lead_suits_this_round[trick_start]
		elif not lead_card.is_joker:
			lead_suit = lead_card.suit
		# For a currently open trick, the Trick object is authoritative (it knows
		# a Joker's declared suit even in old saves without the history array).
		if game.active_trick != null and trick_start >= game.played_cards_this_round.size() - game.active_trick.played_cards.size():
			lead_suit = game.active_trick.lead_suit
		if lead_suit >= 0:
			for offset in range(1, trick_size):
				var card_index := trick_start + offset
				var card: Card = game.played_cards_this_round[card_index]
				if card.is_joker or card.suit == lead_suit:
					continue
				var player_index := int(game.played_cards_by_this_round[card_index])
				_mark_void_suit(result, player_index, lead_suit)
				if game.current_round.trump != Round.TrumpSuit.NONE and game.current_round.trump != Round.TrumpSuit.RANDOM and card.suit != game.current_round.trump:
					_mark_void_suit(result, player_index, game.current_round.trump)
		trick_start += trick_size
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
	legal_cards: Array[Card],
	team_mode := false
) -> Array[Card]:
	var regular_cards := _regular_cards(legal_cards)
	if regular_cards.is_empty():
		return legal_cards
	var void_suits := _infer_public_void_suits(game)
	var safe_suits: Array[Card] = []
	for card in regular_cards:
		if not _another_player_is_known_void(game, player_index, card.suit, void_suits, team_mode):
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
	void_suits: Dictionary,
	team_mode := false
) -> bool:
	for other_index in game.players.size():
		if other_index == player_index or game.players[other_index].hand.is_empty():
			continue
		# In 2v2 do not force the PARTNER to trump on misere. An opponent being
		# void is not a reason to reject a potentially useful losing lead.
		if team_mode and other_index != (player_index + 2) % game.players.size():
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
	for rank in range(int(card.rank) + 1, int(Card.Rank.ACE) + 1):
		if card.suit == Card.Suit.CLUBS and rank == Card.Rank.SEVEN:
			continue
		if not known_keys.has("%d_%d" % [card.suit, rank]):
			return true
	return false


static func _filter_candidates(game: Game, player_index: int, cards: Array[Card], team_mode: bool) -> Array[Card]:
	if game.current_round.round_type == Round.RoundType.MISERE and game.active_trick == null:
		return _filter_misere_lead_candidates(game, player_index, cards, team_mode)
	var player := game.players[player_index]
	if not _wants_trick(game.current_round.round_type, player) or game.active_trick == null:
		return cards
	# In no-trump an off-suit master cannot win this trick. Keep it for a later
	# lead while there is a non-master discard. No hidden hand is inspected.
	if game.current_round.trump != Round.TrumpSuit.NONE:
		return cards
	var void_suits := _infer_public_void_suits(game)
	var preserved: Array[Card] = []
	for card in cards:
		if card.is_joker or _would_win_now(game, card) or _has_publicly_possible_higher_card(game, player_index, card, void_suits):
			preserved.append(card)
	return preserved if not preserved.is_empty() else cards


static func _choose_taking_lead(game: Game, player: Player, cards: Array[Card]) -> Card:
	var void_suits := _infer_public_void_suits(game)
	var masters: Array[Card] = []
	for card in cards:
		if not _has_publicly_possible_higher_card(game, player.player_id, card, void_suits):
			masters.append(card)
	if not masters.is_empty():
		return _select_by_strength(game, masters, true)
	# No cashable high card: develop a suit without throwing away its king.
	return _select_by_strength(game, cards, false)


static func _current_winner(game: Game) -> int:
	if game.active_trick == null or game.active_trick.played_cards.is_empty():
		return -1
	var trick := _clone_trick(game.active_trick)
	trick.player_count = trick.played_cards.size()
	return trick.get_winner_index()


static func _should_leave_partner_trick(game: Game, player_index: int) -> bool:
	if game.players.size() != 4 or _current_winner(game) != (player_index + 2) % 4:
		return false
	var player := game.players[player_index]
	var partner := game.players[(player_index + 2) % 4]
	var type := game.current_round.round_type
	if type == Round.RoundType.MISERE:
		return false
	if type == Round.RoundType.GOLDEN:
		# First trick removes the -50 zero-trick penalty. Do not deprive a
		# zero-trick partner, but let a zero-trick actor overtake a safe partner.
		return partner.tricks_taken == 0 or player.tricks_taken > 0
	return partner.tricks_taken < partner.bid or (partner.tricks_taken > partner.bid and player.tricks_taken == player.bid)


static func choose_joker_mode(game: Game, player_index: int, team_mode := false) -> Trick.JokerMode:
	if team_mode and game.active_trick != null and game.active_trick.played_cards.size() == game.players.size() - 1:
		if _should_leave_partner_trick(game, player_index):
			return Trick.JokerMode.NORMAL_CARD_WINS
	return Trick.JokerMode.JOKER_WINS if _wants_trick(game.current_round.round_type, game.players[player_index]) else Trick.JokerMode.NORMAL_CARD_WINS


static func _card_tie_break(game: Game, player_index: int, card: Card, team_mode: bool) -> float:
	var priority := -float(_card_strength(game, card)) * 0.0001
	if game.active_trick != null and _would_win_now(game, card):
		if game.current_round.round_type == Round.RoundType.GOLDEN:
			priority += -0.05 if team_mode and _should_leave_partner_trick(game, player_index) else 0.05
	return priority


static func _roll_out_round(game: Game, random: RandomNumberGenerator, team_mode := false) -> void:
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
		var selected := _choose_rollout_card(game, player, legal_cards, random, team_mode)
		if selected == null or not _play_card_with_policy(game, player_index, selected, team_mode):
			return


static func _choose_rollout_card(
	game: Game,
	player: Player,
	legal_cards: Array[Card],
	random: RandomNumberGenerator,
	team_mode := false
) -> Card:
	legal_cards = _filter_candidates(game, player.player_id, legal_cards, team_mode)
	if legal_cards.size() == 1:
		return legal_cards[0]
	var wants_trick := _wants_trick(game.current_round.round_type, player)
	if game.active_trick == null:
		var regular_leads := _regular_cards(legal_cards)
		if regular_leads.is_empty():
			return legal_cards[0]
		if game.current_round.round_type == Round.RoundType.MISERE:
			var player_index := game.players.find(player)
			regular_leads = _filter_misere_lead_candidates(game, player_index, regular_leads, team_mode)
		if wants_trick:
			return _choose_taking_lead(game, player, regular_leads)
		return _select_by_strength(game, regular_leads, false)

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
	if team_mode and _should_leave_partner_trick(game, player.player_id) and not losers.is_empty():
		return _select_by_strength(game, losers, false)
	if wants_trick:
		if not winners.is_empty():
			# Before the last seat, a barely winning card can still be covered.
			# Cash a master when available instead of letting the whole suit pass.
			if game.active_trick.played_cards.size() < game.players.size() - 1:
				var void_suits := _infer_public_void_suits(game)
				var masters: Array[Card] = []
				for winner in winners:
					if not _has_publicly_possible_higher_card(game, player.player_id, winner, void_suits):
						masters.append(winner)
				if not masters.is_empty():
					return _select_by_strength(game, masters, false)
			return _select_by_strength(game, winners, false)
		if joker != null and (game.current_round.round_type == Round.RoundType.GOLDEN or player.tricks_taken > player.bid or player.hand.size() <= player.bid - player.tricks_taken or losers.is_empty()):
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


static func _play_card_with_policy(game: Game, player_index: int, card: Card, team_mode := false) -> bool:
	if not card.is_joker:
		return game.play_card(player_index, card)
	var player := game.players[player_index]
	var joker_mode := choose_joker_mode(game, player_index, team_mode)
	var wants_trick := joker_mode == Trick.JokerMode.JOKER_WINS
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
	for player_index in game.players.size():
		if not team_mode and player_index != actor_index:
			continue
		var sign_value := 1.0 if player_index in participant_indices else -1.0
		var player := game.players[player_index]
		var round_score := ScoreCalculator.calculate_round_score(round_type, player.bid, player.tricks_taken)
		utility += sign_value * float(round_score) * 10.0
		if ScoreCalculator.is_exact_order(round_type, player.bid, player.tricks_taken):
			utility += sign_value * 0.25
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
