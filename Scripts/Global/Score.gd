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

# NUEVO: info del último intento
var latest_total_score : int = 0
var is_new_best : bool = false

const difficult = {
	"easy": "easy",
	"medium": "medium",
	"hard": "hard"
}
var actualDifficult = difficult["easy"]

func _ready():
	PlayerScore = OrderItScore + PuzzleScore + MatchItScore
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
