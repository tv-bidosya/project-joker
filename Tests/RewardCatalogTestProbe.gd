extends SceneTree

const RewardCatalogResource = preload("res://Scripts/core/RewardCatalog.gd")


func _init() -> void:
	var starter: Dictionary = RewardCatalogResource.create_inventory_for_xp(0)
	assert((starter.get("card_backs", []) as Array).size() == 1)
	assert((starter.get("avatars", []) as Array).size() == 4)
	assert((starter.get("table_themes", []) as Array).size() == 1)
	assert((starter.get("reactions", []) as Array).size() == 20)
	assert((starter.get("gifts", []) as Array).size() == 10)
	assert((starter.get("soundbar_folders", []) as Array) == ["soundbar_folder_base"])

	var first_threshold: Dictionary = RewardCatalogResource.create_inventory_for_xp(500)
	assert((first_threshold.get("card_backs", []) as Array).size() == 2)
	assert((first_threshold.get("reactions", []) as Array).size() == 25)
	assert((first_threshold.get("gifts", []) as Array).size() == 13)
	assert((first_threshold.get("soundbar_folders", []) as Array) == ["soundbar_folder_base", "soundbar_folder_01"])

	var complete: Dictionary = RewardCatalogResource.create_inventory_for_xp(10500)
	assert((complete.get("card_backs", []) as Array).size() == 11)
	assert((complete.get("avatars", []) as Array).size() == 14)
	assert((complete.get("table_themes", []) as Array).size() == 11)
	assert((complete.get("reactions", []) as Array).size() == 70)
	assert((complete.get("gifts", []) as Array).size() == 40)
	assert((complete.get("soundbar_folders", []) as Array).size() == 5)
	assert(RewardCatalogResource.get_next_reward(10499).get("xp", 0) == 10500)
	assert(RewardCatalogResource.get_next_reward(10500).is_empty())
	assert(RewardCatalogResource.get_newly_unlocked(499, 500).size() == 10)
	print("REWARD_CATALOG_TEST_PASS")
	quit()
