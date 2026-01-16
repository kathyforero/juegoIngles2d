extends Node
var PlayerScore = 0
var OrderItScore = 0
var PuzzleScore = 0
var MatchItScore = 0
enum Games {OrderIt, Puzzle, MatchIt}
var LatestGame = null
var newScore = 0
var fastBonus = 0
var perfectBonus = 0
const difficult = {
	"easy": "easy",
	"medium": "medium",
	"hard": "hard"
}
var actualDifficult = difficult["easy"]
# Called when the node enters the scene tree for the first time.

var practice_mode: bool = false

const ACHIEVEMENTS_FILE = "/Progress/achievements.dat"
const ACHIEVEMENT_TEXTURES = {
	"puzzle": "res://Sprites/buttons/LogroPuzzle.png",
	"match": "res://Sprites/buttons/LogroMatchIt.png",
	"order": "res://Sprites/buttons/LogroOrderIt.png",
	"speed": "res://Sprites/buttons/LogroSpeed.png",
	"perfect": "res://Sprites/buttons/LogroPerfect.png"
}
const ACHIEVEMENT_UNKNOWN_TEXTURE = "res://Sprites/buttons/LogroUnknown.png"

var achievements_data: Dictionary = {}
var pending_achievements: Array[String] = []

func _ready():
	PlayerScore = OrderItScore + PuzzleScore + MatchItScore
	_load_achievements()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _get_achievements_path() -> String:
	return Global.rutaArchivos + ACHIEVEMENTS_FILE

func _default_achievements_data() -> Dictionary:
	return {
		"achievements": {
			"puzzle": false,
			"match": false,
			"order": false,
			"speed": false,
			"perfect": false
		},
		"completed": {
			"puzzle": {"easy": false, "medium": false, "hard": false},
			"match": {"easy": false, "medium": false, "hard": false},
			"order": {"easy": false, "medium": false, "hard": false}
		}
	}

func _ensure_progress_dir() -> void:
	var dir_path = Global.rutaArchivos + "/Progress"
	if !DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)

func _load_achievements() -> void:
	_ensure_progress_dir()
	var path = _get_achievements_path()
	var defaults = _default_achievements_data()
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = file.get_var()
		file.close()
		achievements_data = defaults
		if typeof(data) == TYPE_DICTIONARY:
			var saved_achievements = data.get("achievements", {})
			for key in achievements_data["achievements"].keys():
				if saved_achievements.has(key):
					achievements_data["achievements"][key] = saved_achievements[key]
			var saved_completed = data.get("completed", {})
			for game_key in achievements_data["completed"].keys():
				if saved_completed.has(game_key):
					for diff_key in achievements_data["completed"][game_key].keys():
						if saved_completed[game_key].has(diff_key):
							achievements_data["completed"][game_key][diff_key] = saved_completed[game_key][diff_key]
	else:
		achievements_data = defaults
		_save_achievements()

func _save_achievements() -> void:
	var path = _get_achievements_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(achievements_data)
	file.close()

func _unlock_achievement(achievement_id: String) -> void:
	if !achievements_data["achievements"].get(achievement_id, false):
		achievements_data["achievements"][achievement_id] = true
		if !pending_achievements.has(achievement_id):
			pending_achievements.append(achievement_id)

func _mark_completed(game_id: String, difficulty_id: String) -> void:
	if !achievements_data["completed"].has(game_id):
		return
	match difficulty_id:
		"easy":
			achievements_data["completed"][game_id]["easy"] = true
		"medium":
			achievements_data["completed"][game_id]["easy"] = true
			achievements_data["completed"][game_id]["medium"] = true
		"hard":
			achievements_data["completed"][game_id]["easy"] = true
			achievements_data["completed"][game_id]["medium"] = true
			achievements_data["completed"][game_id]["hard"] = true

func _check_game_achievement(game_id: String) -> void:
	if !achievements_data["completed"].has(game_id):
		return
	var completed = achievements_data["completed"][game_id]
	if completed["easy"] and completed["medium"] and completed["hard"]:
		_unlock_achievement(game_id)

func register_minigame_victory(game_id: String, difficulty_id: String, time_spent: float, is_perfect: bool) -> void:
	if practice_mode:
		return
	_mark_completed(game_id, difficulty_id)
	_check_game_achievement(game_id)
	if time_spent <= 30.0:
		_unlock_achievement("speed")
	if is_perfect:
		_unlock_achievement("perfect")
	_save_achievements()

func has_pending_achievement() -> bool:
	return pending_achievements.size() > 0

func pop_next_pending_achievement() -> String:
	if pending_achievements.size() == 0:
		return ""
	return pending_achievements.pop_front()

func get_achievement_texture_path(achievement_id: String) -> String:
	return ACHIEVEMENT_TEXTURES.get(achievement_id, "")

func get_unknown_achievement_texture_path() -> String:
	return ACHIEVEMENT_UNKNOWN_TEXTURE

func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievements_data["achievements"].get(achievement_id, false)

func get_unlocked_achievements_count() -> int:
	var count = 0
	for key in achievements_data["achievements"].keys():
		if achievements_data["achievements"][key]:
			count += 1
	return count

func get_achievement_message(achievement_id: String, english: bool) -> String:
	var name = ""
	match achievement_id:
		"puzzle":
			name = "Puzzle"
		"match":
			name = "Match It"
		"order":
			name = "Order It"
		"speed":
			name = "Speed"
		"perfect":
			name = "Perfect"
		_:
			name = "Achievement"

	if english:
		match achievement_id:
			"puzzle":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round on every difficulty of this minigame. Keep it up :)"
			"match":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round on every difficulty of this minigame. Keep it up :)"
			"order":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round on every difficulty of this minigame. Keep it up :)"
			"speed":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round in 30 seconds or less. Keep it up :)"
			"perfect":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round without mistakes. Keep it up :)"
			_:
				return "Congratulations! You earned a new achievement. Keep it up :)"
	else:
		match achievement_id:
			"puzzle":
				return "Felicidades! Has obtenido el logro de \"" + name + "\" por haber completado una ronda en cada dificultad de este minijuego. Sigue asi :)"
			"match":
				return "Felicidades! Has obtenido el logro de \"" + name + "\" por haber completado una ronda en cada dificultad de este minijuego. Sigue asi :)"
			"order":
				return "Felicidades! Has obtenido el logro de \"" + name + "\" por haber completado una ronda en cada dificultad de este minijuego. Sigue asi :)"
			"speed":
				return "Felicidades! Has obtenido el logro de \"" + name + "\" por haber completado una ronda en 30 segundos o menos. Sigue asi :)"
			"perfect":
				return "Felicidades! Has obtenido el logro de \"" + name + "\" por haber completado una ronda sin equivocarte. Sigue asi :)"
			_:
				return "Felicidades! Has obtenido un nuevo logro. Sigue asi :)"
