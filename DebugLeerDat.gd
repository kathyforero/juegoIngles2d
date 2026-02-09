extends Node

func _ready():
	_leer_score("user://Scores/puntajesPuzzle.dat")
	_leer_score("user://Scores/puntajesMatch.dat")
	_leer_score("user://Scores/puntajesOrder.dat")

func _leer_score(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("No existe: ", path)
		return

	var f = FileAccess.open(path, FileAccess.READ)
	var data = f.get_var()
	f.close()

	print("\n========== ", path, " ==========")
	print(data)    # Te imprime el Dictionary completo (easy/medium/hard)
