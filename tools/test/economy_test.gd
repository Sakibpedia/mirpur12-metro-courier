extends Node
## Wallet, bike upgrades, rider XP/skills, quests and persistence.
func _ready() -> void:
	var fails := 0
	var snap := {"money": Game.money, "bike": Game.bike_level, "xp": Game.xp,
		"level": Game.level, "sp": Game.skill_points, "skills": Game.skills.duplicate(true)}
	for i in range(1, 16):
		var d: Dictionary = Game.job_data(i)
		if int(d.get("deliveries", 0)) <= 0: fails += 1
		if (d.get("quests", []) as Array).size() != 3: fails += 1
	Game.money = 2000
	var speed0 := Game.top_speed()
	if not Game.upgrade_bike(): fails += 1
	if Game.top_speed() <= speed0: fails += 1
	Game.skill_points = 2
	if not Game.allocate_skill("speed"): fails += 1
	if Game.top_speed() <= speed0: fails += 1
	var lvl := Game.level
	if not Game.grant_quest("econ_q", 100, Game.xp_to_next() + 5): fails += 1
	if Game.level <= lvl: fails += 1
	Game.complete_job(1, 4, 0, 1500)
	if Game.unlocked < 2: fails += 1
	if Game.rank() == "": fails += 1
	Game.save_game()
	Game.money = 0
	Game.load_game()
	if Game.money <= 0: fails += 1
	Game.money = snap["money"]; Game.bike_level = snap["bike"]
	Game.xp = snap["xp"]; Game.level = snap["level"]
	Game.skill_points = snap["sp"]; Game.skills = snap["skills"]
	Game.save_game()
	if fails > 0:
		print("[ECON] FAIL %d checks" % fails)
		get_tree().quit(1)
	print("[ECON] PASS - 15 jobs, bike upgrades, XP/skills, quests, save/reload")
	get_tree().quit(0)
