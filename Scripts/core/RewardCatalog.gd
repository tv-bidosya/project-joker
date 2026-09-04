class_name RewardCatalog

extends RefCounted


const CATEGORY_CARD_BACKS := "card_backs"
const CATEGORY_AVATARS := "avatars"
const CATEGORY_TABLE_THEMES := "table_themes"
const CATEGORY_REACTIONS := "reactions"
const CATEGORY_GIFTS := "gifts"
const CATEGORY_SOUNDBAR_FOLDERS := "soundbar_folders"
const CATEGORY_ORDER := [
	CATEGORY_CARD_BACKS,
	CATEGORY_AVATARS,
	CATEGORY_TABLE_THEMES,
	CATEGORY_REACTIONS,
	CATEGORY_GIFTS,
	CATEGORY_SOUNDBAR_FOLDERS
]

const STARTER_INVENTORY := {
	CATEGORY_CARD_BACKS: ["card_back_classic"],
	CATEGORY_AVATARS: ["avatar_fox_v2", "avatar_clown", "avatar_ace", "avatar_mystery"],
	CATEGORY_TABLE_THEMES: ["table_classic"],
	CATEGORY_REACTIONS: [
		"reaction_starter_01", "reaction_starter_02", "reaction_starter_03", "reaction_starter_04", "reaction_starter_05",
		"reaction_starter_06", "reaction_starter_07", "reaction_starter_08", "reaction_starter_09", "reaction_starter_10",
		"reaction_starter_11", "reaction_starter_12", "reaction_starter_13", "reaction_starter_14", "reaction_starter_15",
		"reaction_starter_16", "reaction_starter_17", "reaction_starter_18", "reaction_starter_19", "reaction_starter_20"
	],
	CATEGORY_GIFTS: [
		"gift_starter_01", "gift_starter_02", "gift_starter_03", "gift_starter_04", "gift_starter_05",
		"gift_starter_06", "gift_starter_07", "gift_starter_08", "gift_starter_09", "gift_starter_10"
	],
	CATEGORY_SOUNDBAR_FOLDERS: ["soundbar_folder_base"]
}


static func create_inventory_for_xp(xp: int) -> Dictionary:
	var inventory := _duplicate_starter_inventory()
	for reward in get_all_rewards():
		if int(reward.get("xp", 0)) <= maxi(0, xp):
			(inventory[str(reward.get("category", ""))] as Array).append(str(reward.get("id", "")))
	return inventory


static func get_newly_unlocked(previous_xp: int, current_xp: int) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for reward in get_all_rewards():
		var threshold := int(reward.get("xp", 0))
		if threshold > maxi(0, previous_xp) and threshold <= maxi(0, current_xp):
			rewards.append(reward.duplicate(true))
	return rewards


static func get_next_reward(xp: int) -> Dictionary:
	var next_threshold := 2147483647
	var items: Array[Dictionary] = []
	for reward in get_all_rewards():
		var threshold := int(reward.get("xp", 0))
		if threshold <= maxi(0, xp):
			continue
		if threshold < next_threshold:
			next_threshold = threshold
			items.clear()
		if threshold == next_threshold:
			items.append(reward.duplicate(true))
	if items.is_empty():
		return {}
	return {"xp": next_threshold, "items": items}


static func get_all_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for reward_number in range(1, 11):
		var threshold := reward_number * 500
		rewards.append(_reward(CATEGORY_CARD_BACKS, "card_back_reward_%02d" % reward_number, threshold))
		for item_offset in range(5):
			rewards.append(_reward(CATEGORY_REACTIONS, "reaction_%03d" % ((reward_number - 1) * 5 + item_offset + 1), threshold))
		for item_offset in range(3):
			rewards.append(_reward(CATEGORY_GIFTS, "gift_%03d" % ((reward_number - 1) * 3 + item_offset + 1), threshold))
		rewards.append(_reward(CATEGORY_AVATARS, "avatar_reward_%02d" % reward_number, reward_number * 1000))
		rewards.append(_reward(CATEGORY_TABLE_THEMES, "table_theme_reward_%02d" % reward_number, 1500 + (reward_number - 1) * 1000))
	for folder_data in [[1, 500], [2, 1500], [3, 3500], [4, 10000]]:
		rewards.append(_reward(CATEGORY_SOUNDBAR_FOLDERS, "soundbar_folder_%02d" % int(folder_data[0]), int(folder_data[1])))
	rewards.sort_custom(func(left: Dictionary, right: Dictionary):
		var left_xp := int(left.get("xp", 0))
		var right_xp := int(right.get("xp", 0))
		return left_xp < right_xp or (left_xp == right_xp and str(left.get("id", "")) < str(right.get("id", "")))
	)
	return rewards


static func _reward(category: String, reward_id: String, threshold: int) -> Dictionary:
	return {"category": category, "id": reward_id, "xp": threshold}


static func _duplicate_starter_inventory() -> Dictionary:
	var inventory := {}
	for category in CATEGORY_ORDER:
		inventory[category] = (STARTER_INVENTORY.get(category, []) as Array).duplicate()
	return inventory
