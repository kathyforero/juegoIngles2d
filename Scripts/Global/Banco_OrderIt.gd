# Scripts/Global/Banco_OrderIt.gd
extends Node

var easy: Array = []
var medium: Array = []
var hard: Array = []

func _ready():
	var path = "res://JsonJuegos/Banco_OrderIt.json"
	if not FileAccess.file_exists(path):
		push_error("Banco_OrderIt.json not found at: " + path)
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open Banco_OrderIt.json")
		return
	
	var text := file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Banco_OrderIt.json has invalid format")
		return
	
	# Cargar listas por dificultad
	easy   = data.get("easy",   [])
	medium = data.get("medium", [])
	hard   = data.get("hard",   [])
