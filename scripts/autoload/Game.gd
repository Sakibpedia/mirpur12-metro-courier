extends Node
## Mirpur 12 Metro Courier - campaign state, wallet, rider RPG and saves.

signal state_changed

const JOB_COUNT := 15
const SAVE_PATH := "user://mirpur12_courier.cfg"
const JOB_NAMES := [
	"Kachabazar First Drop", "Road 7 Rush", "Milk Vita Parcel",
	"Begum Rokeya Express", "Kalshi Flyover Run", "Avenue 2 Swap",
	"DOHS Link Delivery", "School Gate Drop", "Clinic Medicine Run",
	"Road 12 Night Shift", "Market Basket Job", "Long Route Bonus",
	"Rush Hour Gauntlet", "Bridge Crossing", "Metro Final Haul",
]
const JOB_BN := [
	"কাচাবাজার প্রথম ডেলিভারি", "রোড ৭ রাশ", "মিল্ক ভিটা পার্সেল",
	"বেগম রোকেয়া এক্সপ্রেস", "কালশী ফ্লাইওভার রান", "অ্যাভিনিউ ২ বিনিময়",
	"ডিওএইচএস ডেলিভারি", "স্কুল গেট ড্রপ", "ক্লিনিকে ওষুধ",
	"রোড ১২ রাত্রি শিফট", "বাজার বাস্কেট", "দীর্ঘ রুট বোনাস",
	"রাশ আওয়ার চ্যালেঞ্জ", "ব্রিজ ক্রসিং", "মেট্রো চূড়ান্ত হল",
]
const SKILL_NAMES := ["speed", "handling", "navigation"]
const SKILL_BN := {"speed": "গতি", "handling": "নিয়ন্ত্রণ", "navigation": "রুট জ্ঞান"}

var job: int = 1
var unlocked: int = 1
var money: int = 600
var xp: int = 0
var level: int = 1
var skill_points: int = 0
var skills: Dictionary = {"speed": 0, "handling": 0, "navigation": 0}
var bike_level: int = 0
var records: Dictionary = {}
var quests_done: Dictionary = {}
var settings: Dictionary = {"sfx": true}
var last_result: Dictionary = {}


func _ready() -> void:
	load_game()


func job_data(idx: int) -> Dictionary:
	var i: int = clampi(idx, 1, JOB_COUNT) - 1
	var deliveries_count: int = 2 + i % 4
	return {
		"index": i + 1,
		"name": JOB_NAMES[i],
		"name_bn": JOB_BN[i],
		"pickups": 2 + i % 3,
		"deliveries": deliveries_count,
		"time_limit": 120.0 + float(i) * 5.0,
		"traffic": 8 + i * 2,
		"reward": 180 + i * 55,
		"quests": [
			{"id": "j%d_deliver" % (i + 1), "type": "deliver", "target": deliveries_count,
				"reward": 90 + i * 12, "xp": 50 + i * 8, "text": "পার্সেল পৌঁছে দিন"},
			{"id": "j%d_clean" % (i + 1), "type": "clean", "target": i / 4,
				"reward": 110 + i * 10, "xp": 55 + i * 9, "text": "দুর্ঘটনা ছাড়াই চলুন"},
			{"id": "j%d_time" % (i + 1), "type": "time", "target": 60,
				"reward": 100 + i * 10, "xp": 45 + i * 8, "text": "সময়ের আগে শেষ করুন"},
		],
	}


func xp_to_next() -> int:
	return 140 + level * 80


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		skill_points += 1
		state_changed.emit()
	save_game()


func allocate_skill(name: String) -> bool:
	if skill_points <= 0 or not skills.has(name) or int(skills[name]) >= 5:
		return false
	skills[name] = int(skills[name]) + 1
	skill_points -= 1
	save_game()
	state_changed.emit()
	return true


func skill(name: String) -> int:
	return int(skills.get(name, 0))


func top_speed() -> float:
	return 165.0 + float(bike_level) * 18.0 + 9.0 * float(skill("speed"))


func crash_penalty() -> float:
	return maxf(0.2, 1.0 - 0.12 * float(skill("handling")))


func time_bonus() -> float:
	return 8.0 * float(skill("navigation"))


func grant_quest(qid: String, reward: int, xp_reward: int) -> bool:
	if quests_done.has(qid):
		return false
	quests_done[qid] = true
	money += reward
	add_xp(xp_reward)
	save_game()
	state_changed.emit()
	return true


func spend(cost: int) -> bool:
	if money < cost: return false
	money -= cost
	save_game()
	state_changed.emit()
	return true


func earn(amount: int) -> void:
	money += amount
	save_game()
	state_changed.emit()


func upgrade_bike() -> bool:
	var cost := 220 * (bike_level + 1)
	if bike_level >= 4 or not spend(cost): return false
	bike_level += 1
	save_game()
	state_changed.emit()
	return true


func complete_job(idx: int, delivered: int, crashes: int, score: int) -> void:
	var d := job_data(idx)
	money += int(d.get("reward", 0)) + score
	if delivered >= int(d.get("deliveries", 0)):
		var grade := "A" if crashes == 0 else "B"
		records[str(idx)] = {"score": score, "delivered": delivered, "crashes": crashes, "grade": grade}
		if idx >= unlocked and idx < JOB_COUNT:
			unlocked = idx + 1
		job = clampi(idx + 1, 1, JOB_COUNT)
		last_result = {"success": true, "grade": grade, "reward": int(d.get("reward", 0))}
	else:
		last_result = {"success": false, "reason": "লক্ষ্য পূর্ণ হয়নি"}
	add_xp(60 + idx * 12)
	save_game()
	state_changed.emit()


func fail_job(reason: String) -> void:
	last_result = {"success": false, "reason": reason}
	state_changed.emit()


func total_score() -> int:
	var t := 0
	for r in records.values():
		t += int((r as Dictionary).get("score", 0))
	return t


func rank() -> String:
	var s := total_score()
	if s >= 16000: return "Legend Courier"
	if s >= 9000: return "Senior Rider"
	if s >= 4000: return "Courier"
	return "New Rider"


func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("progress", "job", job)
	cf.set_value("progress", "unlocked", unlocked)
	cf.set_value("progress", "records", records)
	cf.set_value("wallet", "money", money)
	cf.set_value("wallet", "bike_level", bike_level)
	cf.set_value("rider", "xp", xp)
	cf.set_value("rider", "level", level)
	cf.set_value("rider", "skill_points", skill_points)
	cf.set_value("rider", "skills", skills)
	cf.set_value("rider", "quests_done", quests_done)
	cf.set_value("settings", "values", settings)
	cf.save(SAVE_PATH)


func load_game() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	job = clampi(int(cf.get_value("progress", "job", 1)), 1, JOB_COUNT)
	unlocked = clampi(int(cf.get_value("progress", "unlocked", 1)), 1, JOB_COUNT)
	records = cf.get_value("progress", "records", {})
	money = int(cf.get_value("wallet", "money", 600))
	bike_level = int(cf.get_value("wallet", "bike_level", 0))
	xp = int(cf.get_value("rider", "xp", 0))
	level = int(cf.get_value("rider", "level", 1))
	skill_points = int(cf.get_value("rider", "skill_points", 0))
	skills = cf.get_value("rider", "skills", {"speed": 0, "handling": 0, "navigation": 0})
	quests_done = cf.get_value("rider", "quests_done", {})
	settings = cf.get_value("settings", "values", settings)
