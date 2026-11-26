extends Node
## Verifies the exact Mirpur 12 OSM urban data used by the game.
var city
var t := 0.0
var reported := false

func _ready() -> void:
	city = load("res://scripts/world/City2D.gd").new()
	add_child(city)

func _process(delta: float) -> void:
	t += delta
	if t < 1.0 or reported:
		return
	reported = true
	var nb: int = city.buildings.size()
	var nr: int = city.roads.size()
	var nn: int = city.road_names.size()
	var na: int = city.amenities.size()
	var ns: int = city.shelters.size()
	var nf: int = city.flood_roads.size()
	var ok: bool = nb >= 1400 and nr >= 750 and nn >= 140 and na >= 1000 and ns >= 400 and nf >= 50
	print("[CITY2D] buildings=%d roads=%d named=%d amenities=%d shelters=%d flood_segments=%d" % [nb, nr, nn, na, ns, nf])
	print("[CITY2D] %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
