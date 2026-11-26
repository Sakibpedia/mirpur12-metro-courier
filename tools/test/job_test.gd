extends Node
## Playthrough test for one courier job (JOB=1..15) using real interaction hooks.
var job
var t := 0.0
var idx := 1
var reported := false
var fails := 0

func _ready() -> void:
	var env := OS.get_environment("JOB")
	idx = int(env) if env != "" else 1
	Game.job = idx
	job = (load("res://scenes/CourierJob.tscn") as PackedScene).instantiate()
	add_child(job)

func _ck(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("[JOB] FAIL J%d %s" % [idx, what])

func _process(delta: float) -> void:
	t += delta
	if t > 120.0:
		print("[JOB] FAIL J%d timeout" % idx)
		get_tree().quit(1)
	if reported or t < 2.0 or job.get("running") != true:
		return
	reported = true
	var city = job.get("city")
	var pickups: Array = job.get("pickups")
	var deliveries: Array = job.get("deliveries")
	var jdata: Dictionary = job.get("data")
	_ck(city.get("buildings").size() >= 1400, "city built")
	_ck(city.get("roads").size() >= 750, "real roads")
	_ck(job.get("traffic").size() >= 8, "traffic spawned")
	_ck(pickups.size() >= 2 and deliveries.size() >= 2, "route points")
	var target := int(jdata.get("deliveries", 2))
	Game.money = 500
	for i in target:
		job.get("hero").position = pickups[mini(i, pickups.size() - 1)]
		job.call("interact")
		job.get("hero").position = deliveries[mini(i, deliveries.size() - 1)]
		job.call("interact")
	_ck(int(job.get("delivered")) >= target, "delivered %d/%d" % [int(job.get("delivered")), target])
	job.call("_check_quests")
	_ck(Game.quests_done.has(str((jdata["quests"][0] as Dictionary)["id"])), "delivery quest rewarded")
	job.call("end_job", true)
	_ck(job.get("ended") == true, "job ended")
	if fails == 0:
		print("[JOB] PASS J%d - %d deliveries, %d traffic, score %d" % [
			idx, int(job.get("delivered")), job.get("traffic").size(), int(job.get("score"))])
		get_tree().quit(0)
	else:
		get_tree().quit(1)
