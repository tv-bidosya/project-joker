class_name ScoreCalculator

extends RefCounted


static func calculate_round_score(round_type: Round.RoundType, bid: int, tricks_taken: int) -> int:
	if tricks_taken < 0:
		return 0

	match round_type:
		Round.RoundType.NORMAL:
			return _calculate_bid_score(bid, tricks_taken, 10, 5, 10)
		Round.RoundType.DARK:
			return _calculate_bid_score(bid, tricks_taken, 15, 50, 10)
		Round.RoundType.NO_TRUMP:
			return tricks_taken * 15
		Round.RoundType.GOLDEN:
			return -50 if tricks_taken == 0 else tricks_taken * 20
		Round.RoundType.MISERE:
			return 50 if tricks_taken == 0 else tricks_taken * -20

	return 0


static func is_exact_order(round_type: Round.RoundType, bid: int, tricks_taken: int) -> bool:
	return (
		round_type == Round.RoundType.NORMAL
		or round_type == Round.RoundType.DARK
	) and bid >= 0 and bid == tricks_taken


static func _calculate_bid_score(
	bid: int,
	tricks_taken: int,
	exact_score_step: int,
	zero_bid_bonus: int,
	shortage_penalty: int
) -> int:
	if bid < 0:
		return 0

	if bid == 0 and tricks_taken == 0:
		return zero_bid_bonus

	if tricks_taken == bid:
		return bid * exact_score_step

	if tricks_taken > bid:
		return tricks_taken - bid

	return (tricks_taken - bid) * shortage_penalty
