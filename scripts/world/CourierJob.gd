extends Node2D
## One timed delivery job on the real Mirpur 12 road network.

var data: Dictionary = {}
var city = null
var hud = null
var hero = null
var traffic: Array = []
var pickups: Array = []
var deliveries: Array = []
var quest_progress: Dictionary = {}
var carried: int = 0
var delivered: int = 0
var crashes: int = 0
var score: int = 0
var fuel: float = 100.0
var time_left: float = 120.0
var running: bool = true
var ended: bool = false
var paused: bool = false
var rng := RandomNumberGenerator.new()
var _hint: float = 0.0
var _crash_cd: float = 0.0
var cam: Camera2D = null
var marker = null


func _ready() -> void:
	rng.seed = int(Time.get_unix_time_from_system()) + Game.job * 97
	data = Game.job_data(Game.job)
	city = load("res://scripts/world/City2D.gd").new()
	city.flood_level = 0.0
	add_child(city)
	hero = _spawn("courier", "courier", city.extraction)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	hero.add_child(cam)
	cam.make_current()
	marker = CourierMarker.new()
	marker.job = self
	add_child(marker)
	hud = load("res://scripts/ui/CourierHUD.gd").new()
	hud.job = self
	add_child(hud)
	_build_route()
	_spawn_traffic(int(data.get("traffic", 8)))
	for q in (data.get("quests", []) as Array):
		quest_progress[str((q as Dictionary)["id"])] = false
	time_left = float(data.get("time_limit", 120.0)) + Game.time_bonus()
	running = true
	hud.notify("জব: %s — %dটি ডেলিভারি" % [str(data.get("name_bn", "")), int(data.get("deliveries", 0))])


func _spawn(kind: String, team: String, pos: Vector2):
	var a = load("res://scripts/world/Actor2D.gd").new()
	add_child(a)
	a.setup(kind, pos, team, self)
	return a


func _build_route() -> void:
	pickups = []
	deliveries = []
	for i in int(data.get("pickups", 2)):
		var p: Vector2 = city.random_road_point(3000 + i * 23)
		pickups.append(p)
	for i in int(data.get("deliveries", 2)):
		var p: Vector2 = city.random_road_point(5000 + i * 29)
		deliveries.append(p)


func _spawn_traffic(n: int) -> void:
	for i in n:
		var p: Vector2 = city.random_road_point(9000 + i * 31)
		var a = _spawn("traffic", "traffic", p)
		a.target = city.random_road_point(9500 + i * 17)
		a.speed = 55.0 + float(i % 4) * 12.0
		traffic.append(a)


func current_target() -> Vector2:
	if carried <= 0 and pickups.size() > 0:
		return pickups[mini(delivered, pickups.size() - 1)]
	if deliveries.size() > 0:
		return deliveries[mini(delivered, deliveries.size() - 1)]
	return city.extraction


func _process(delta: float) -> void:
	if not running or ended or paused:
		return
	time_left -= delta
	_crash_cd = maxf(0.0, _crash_cd - delta)
	if time_left <= 0.0:
		end_job(false, "সময় শেষ — ডেলিভারি হয়নি")
		return
	_handle_input(delta)
	_update_traffic(delta)
	_check_quests()
	hud.tick(delta)
	hud.refresh()


func _handle_input(delta: float) -> void:
	if hud != null and hud.blocking():
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	var spd := Game.top_speed()
	if fuel <= 0.0: spd *= 0.45
	if Input.is_key_pressed(KEY_SHIFT): spd *= 1.18
	hero.speed = spd
	if dir.length_squared() > 0.0:
		fuel = maxf(0.0, fuel - 2.2 * delta)
	hero.move(dir, delta, city)
	hero.face_towards(get_global_mouse_position())
	if Input.is_key_pressed(KEY_E) and _hint <= 0.0:
		_hint = 0.3
		interact()
	if Input.is_key_pressed(KEY_F) and _hint <= 0.0:
		_hint = 0.3
		if Game.spend(40):
			fuel = mini(100.0, fuel + 50.0)
			hud.notify("জ্বালানি ভরে গেল")
		else:
			hud.notify("জ্বালানির টাকা নেই")
	_hint = maxf(0.0, _hint - delta)


func interact() -> void:
	var target := current_target()
	if hero.position.distance_to(target) < 52.0:
		if carried <= 0:
			carried += 1
			score += 60
			hud.notify("পার্সেল নেওয়া হয়েছে — ডেলিভারিতে যান")
		else:
			carried -= 1
			delivered += 1
			score += 240
			Game.earn(30)
			Sfx.play("pickup")
			hud.notify("ডেলিভারি সম্পন্ন!  +৳30")
		return
	hud.notify("কাছে কোনো পিকআপ/ডেলিভারি পয়েন্ট নেই")


func _update_traffic(delta: float) -> void:
	for a in traffic:
		if a.position.distance_to(a.target) < 24.0:
			a.target = city.random_road_point(int(a.get_instance_id()) % 100000)
		var dir: Vector2 = (a.target - a.position).normalized()
		a.move(dir, delta, city)
		if _crash_cd <= 0.0 and a.position.distance_to(hero.position) < 22.0:
			_crash_cd = 1.2
			crashes += 1
			score = maxi(0, score - 80)
			time_left -= 4.0 * Game.crash_penalty()
			a.target = city.random_road_point(int(a.get_instance_id()) % 100000 + 500)
			hud.notify("ট্রাফিকে আটকে গেল — সময় কমল")
			Sfx.play("hit")


func _check_quests() -> void:
	for q in (data.get("quests", []) as Array):
		var quest: Dictionary = q
		var qid := str(quest["id"])
		if bool(quest_progress.get(qid, false)):
			continue
		var ok := false
		match str(quest["type"]):
			"deliver": ok = delivered >= int(quest["target"])
			"clean": ok = crashes <= int(quest["target"])
			"time": ok = time_left >= float(quest["target"])
		if ok:
			quest_progress[qid] = true
			Game.grant_quest(qid, int(quest["reward"]), int(quest["xp"]))
			hud.notify("লক্ষ্য পূর্ণ: %s" % str(quest["text"]))


func end_job(success: bool = true, reason: String = "") -> void:
	if ended:
		return
	ended = true
	running = false
	var ok: bool = success and delivered >= int(data.get("deliveries", 0))
	if ok:
		Game.complete_job(Game.job, delivered, crashes, score)
	else:
		Game.fail_job(reason if reason != "" else "লক্ষ্য পূর্ণ হয়নি")
	Game.save_game()
	hud.show_summary(ok, delivered, crashes, score, reason)


func retry() -> void:
	get_tree().change_scene_to_file("res://scenes/CourierJob.tscn")


func next_job() -> void:
	Game.save_game()
	get_tree().change_scene_to_file("res://scenes/CourierJob.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_ESCAPE and running:
		if hud != null and hud.blocking():
			hud.close_panel()
		else:
			paused = not paused
			hud.notify("বিরতি — ESC দিয়ে ফিরুন")
	elif event.keycode == KEY_Q and running and not paused and hud != null and not hud.blocking():
		hud.open_rider()
	elif event.keycode == KEY_G and running and not paused and hud != null and not hud.blocking():
		hud.open_quests()
	elif event.keycode == KEY_U and running and not paused and hud != null and not hud.blocking():
		hud.open_upgrade()


class CourierMarker extends Node2D:
	var job

	func _draw() -> void:
		if job == null or job.hud == null:
			return
		var t: Vector2 = job.call("current_target")
		draw_circle(t, 26.0, Color(1.0, 0.78, 0.30, 0.22))
		draw_circle(t, 26.0, Color(1.0, 0.78, 0.30), false, 3.0)
		draw_line(t + Vector2(8, -4), t + Vector2(16, -34), Color(1.0, 0.78, 0.30, 0.7), 2.0)
		draw_circle(t + Vector2(16, -34), 4.5, Color(1.0, 0.88, 0.45))
