extends Node
## Real gameplay frames: menu|job|rider|quests|upgrade|summary
var mode := "menu"
var scene_node = null

func _ready() -> void:
	mode = OS.get_environment("SHOT_MODE")
	if mode == "":
		mode = "menu"
	call_deferred("_setup")
	await get_tree().create_timer(3.0).timeout
	_act()
	await get_tree().create_timer(0.8).timeout
	_capture()

func _setup() -> void:
	if mode == "menu":
		scene_node = (load("res://scenes/MainMenu.tscn") as PackedScene).instantiate()
	else:
		Game.job = 3
		scene_node = (load("res://scenes/CourierJob.tscn") as PackedScene).instantiate()
	add_child(scene_node)

func _act() -> void:
	if scene_node == null or mode == "menu":
		return
	var j = scene_node
	match mode:
		"rider": j.hud.open_rider()
		"quests": j.hud.open_quests()
		"upgrade": j.hud.open_upgrade()
		"summary": j.hud.show_summary(true, 8, 1, 3200, "")
		_: pass

func _capture() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path := "res://docs/images/gameplay-%s.png" % mode
	img.save_png(path)
	print("[SHOT] saved %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	get_tree().quit()
