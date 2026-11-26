extends CanvasLayer
## Courier HUD: timer, parcels, fuel, rider skills, upgrades and summary.

var job = null
var state: String = ""
var notice: String = ""
var notice_time: float = 0.0
var root: Control
var lbl_top: Label
var lbl_mid: Label
var lbl_bottom: Label
var lbl_notice: Label
var fuel_fill: ColorRect
var time_fill: ColorRect
var panel: Panel
var lbl_panel: Label
var mini = null


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var scrim := ColorRect.new()
	scrim.color = Color(0.02, 0.05, 0.07, 0.62)
	scrim.position = Vector2(0, 0)
	scrim.size = Vector2(1280, 132)
	root.add_child(scrim)
	var bottom := ColorRect.new()
	bottom.color = Color(0.02, 0.05, 0.07, 0.60)
	bottom.position = Vector2(0, 636)
	bottom.size = Vector2(1280, 84)
	root.add_child(bottom)
	var bg1 := ColorRect.new()
	bg1.color = Color(0.12, 0.22, 0.24, 0.9)
	bg1.position = Vector2(24, 136)
	bg1.size = Vector2(280, 9)
	root.add_child(bg1)
	fuel_fill = ColorRect.new()
	fuel_fill.color = Color(0.95, 0.74, 0.34)
	fuel_fill.position = Vector2(24, 136)
	fuel_fill.size = Vector2(280, 9)
	root.add_child(fuel_fill)
	var bg2 := ColorRect.new()
	bg2.color = Color(0.12, 0.22, 0.24, 0.9)
	bg2.position = Vector2(24, 150)
	bg2.size = Vector2(280, 7)
	root.add_child(bg2)
	time_fill = ColorRect.new()
	time_fill.color = Color(0.35, 0.85, 0.78)
	time_fill.position = Vector2(24, 150)
	time_fill.size = Vector2(280, 7)
	root.add_child(time_fill)
	lbl_top = _label(Vector2(24, 18), Vector2(900, 38), 24, Color(0.97, 0.85, 0.50))
	lbl_mid = _label(Vector2(24, 58), Vector2(900, 34), 19, Color(0.64, 0.90, 0.88))
	lbl_bottom = _label(Vector2(24, 650), Vector2(1000, 44), 18, Color(0.94, 0.95, 0.92))
	lbl_notice = _label(Vector2(280, 520), Vector2(720, 42), 21, Color(1.0, 0.86, 0.50))
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -330
	panel.offset_top = -220
	panel.offset_right = 330
	panel.offset_bottom = 220
	panel.visible = false
	root.add_child(panel)
	lbl_panel = Label.new()
	lbl_panel.position = Vector2(24, 18)
	lbl_panel.size = Vector2(612, 400)
	panel.add_child(lbl_panel)
	var credit := _label(Vector2(930, 690), Vector2(330, 22), 13, Color(0.60, 0.68, 0.68))
	credit.text = "Made by S M Nazmuz Sakib  •  OSM contributors (ODbL)"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mini = RouteMini.new()
	mini.hud = self
	add_child(mini)


func _label(pos: Vector2, size: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	root.add_child(l)
	return l


func refresh() -> void:
	if job == null:
		return
	var d: Dictionary = job.data
	var mins := int(job.time_left) / 60
	var secs := int(job.time_left) % 60
	lbl_top.text = "রাইডার লেভেল %d (%d/%d XP) • জব %d/15 — %s | ৳%d | স্কোর %d" % [
		Game.level, Game.xp, Game.xp_to_next(), Game.job, str(d.get("name_bn", "")), Game.money, job.score]
	lbl_mid.text = "সময় %02d:%02d • ডেলিভারি %d/%d • হাতে %d • দুর্ঘটনা %d • জ্বালানি %d%% • বাইক Lv%d • %s" % [
		mins, secs, job.delivered, int(d.get("deliveries", 0)), job.carried,
		job.crashes, int(job.fuel), Game.bike_level, Game.rank()]
	lbl_bottom.text = "WASD চলুন • E পিকআপ/ডেলিভারি • F জ্বালানি • Q রাইডার • G কুয়েস্ট • U বাইক আপগ্রেড • ESC বিরতি"
	lbl_notice.text = notice if notice_time > 0.0 else ""
	fuel_fill.size.x = clampf(job.fuel / 100.0, 0.0, 1.0) * 280.0
	var total := maxf(1.0, float(d.get("time_limit", 120.0)))
	time_fill.size.x = clampf(job.time_left / total, 0.0, 1.0) * 280.0
	mini.queue_redraw()


func tick(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)


func notify(text: String) -> void:
	notice = text
	notice_time = 3.5


func blocking() -> bool:
	return state != ""


func close_panel() -> void:
	state = ""
	panel.visible = false


func open_rider() -> void:
	state = "rider"
	_refresh_panel()


func open_quests() -> void:
	state = "quests"
	_refresh_panel()


func open_upgrade() -> void:
	state = "upgrade"
	_refresh_panel()


func show_summary(success: bool, delivered: int, crashes: int, score: int, reason: String) -> void:
	state = "summary"
	panel.visible = true
	lbl_panel.text = ("জব সফল" if success else "জব ব্যর্থ") + "\n\n"
	if reason != "":
		lbl_panel.text += reason + "\n\n"
	lbl_panel.text += "ডেলিভারি %d • দুর্ঘটনা %d • স্কোর %d\n" % [delivered, crashes, score]
	lbl_panel.text += "মোট পদমর্যাদা: %s • ৳%d\n\n" % [Game.rank(), Game.money]
	lbl_panel.text += "[N] পরবর্তী জব   [R] আবার   [M] মেনু"


func _refresh_panel() -> void:
	panel.visible = state != ""
	if state == "rider":
		lbl_panel.text = "রাইডার প্রোফাইল\n\nলেভেল %d  XP %d/%d  স্কিল পয়েন্ট %d\n" % [
			Game.level, Game.xp, Game.xp_to_next(), Game.skill_points]
		for i in Game.SKILL_NAMES.size():
			var s := str(Game.SKILL_NAMES[i])
			lbl_panel.text += "%s  %s  স্তর %d/5\n" % [s, str(Game.SKILL_BN.get(s, "")), Game.skill(s)]
		lbl_panel.text += "\n[1] গতি  [2] নিয়ন্ত্রণ  [3] রুট জ্ঞান  [Q] বন্ধ"
	elif state == "quests":
		lbl_panel.text = "জব লক্ষ্য\n\n"
		for q in (job.data.get("quests", []) as Array):
			var quest: Dictionary = q
			var done := bool(job.quest_progress.get(str(quest["id"]), false))
			lbl_panel.text += "[%s] %s (%d)  ৳%d / +%d XP\n" % [
				"X" if done else " ", str(quest["text"]), int(quest["target"]),
				int(quest["reward"]), int(quest["xp"])]
		lbl_panel.text += "\n[G/ESC] বন্ধ"
	elif state == "upgrade":
		lbl_panel.text = "বাইক ওয়ার্কশপ — ৳%d\n\n" % Game.money
		lbl_panel.text += "বর্তমান বাইক স্তর %d\n" % Game.bike_level
		lbl_panel.text += "সর্বোচ্চ গতি %.0f\n" % Game.top_speed()
		lbl_panel.text += "আপগ্রেড খরচ ৳%d\n\n" % (220 * (Game.bike_level + 1))
		lbl_panel.text += "[1] বাইক আপগ্রেড   [U/ESC] বন্ধ"


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	var k: int = event.keycode
	if state == "rider":
		if k >= KEY_1 and k <= KEY_3:
			Game.allocate_skill(str(Game.SKILL_NAMES[k - KEY_1]))
			_refresh_panel()
		if k == KEY_Q or k == KEY_ESCAPE:
			close_panel()
	elif state == "quests":
		if k == KEY_G or k == KEY_ESCAPE:
			close_panel()
	elif state == "upgrade":
		if k == KEY_1:
			if Game.upgrade_bike():
				notify("বাইক আপগ্রেড হয়েছে")
			_refresh_panel()
		if k == KEY_U or k == KEY_ESCAPE:
			close_panel()
	elif state == "summary":
		if k == KEY_M:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		elif k == KEY_R:
			job.retry()
		elif k == KEY_N and bool(Game.last_result.get("success", false)):
			job.next_job()


class RouteMini extends Node2D:
	var hud

	func _draw() -> void:
		if hud == null or hud.job == null:
			return
		var j = hud.job
		var c = j.city
		var center: Vector2 = j.hero.position
		var sc := 0.05
		var size := 210.0
		draw_rect(Rect2(1040, 18, size, size), Color(0.02, 0.07, 0.09, 0.9))
		draw_rect(Rect2(1040, 18, size, size), Color(0.85, 0.72, 0.38), false, 2.0)
		for b in c.render_buildings:
			var r: Rect2 = b["rect"]
			var rp := Rect2(Vector2(1040, 18) + (r.position - center) * sc + Vector2(size / 2, size / 2), r.size * sc)
			if rp.intersects(Rect2(1040, 18, size, size)):
				draw_rect(rp, Color(0.36, 0.34, 0.30, 0.85))
		var t: Vector2 = j.call("current_target")
		var mp: Vector2 = Vector2(1040, 18) + (t - center) * sc + Vector2(size / 2, size / 2)
		draw_line(Vector2(1040 + size / 2, 18 + size / 2), mp, Color(1.0, 0.75, 0.25), 2.0)
		draw_circle(mp, 5.0, Color(1.0, 0.80, 0.35))
		for a in j.traffic:
			var ap: Vector2 = Vector2(1040, 18) + (a.position - center) * sc + Vector2(size / 2, size / 2)
			if ap.x > 1040 and ap.x < 1040 + size and ap.y > 18 and ap.y < 18 + size:
				draw_circle(ap, 2.5, Color(0.95, 0.45, 0.35))
		draw_circle(Vector2(1040 + size / 2, 18 + size / 2), 4.0, Color(0.30, 0.90, 0.80))
