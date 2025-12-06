# Scripts/Global/Banco_MatchIt.gd
extends Node

var easy: Dictionary = {}
var medium: Dictionary = {}
var hard: Dictionary = {}

func _ready():
	var path := "res://JsonJuegos/Banco_MatchIt.json"
	if not FileAccess.file_exists(path):
		push_error("MatchIt.json not found at: " + path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open MatchIt.json")
		return
	
	var text := file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("MatchIt.json has invalid format (expected DICTIONARY).")
		return
	
	# Guardamos por dificultad
	easy   = data.get("easy",   {})
	medium = data.get("medium", {})
	hard   = data.get("hard",   {})
