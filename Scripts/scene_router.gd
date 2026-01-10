extends Node

var last_scene_path: String = ""

func remember_current():
	var cs := get_tree().current_scene
	if cs and cs.scene_file_path != "":
		last_scene_path = cs.scene_file_path

func go_back(default_path: String):
	if last_scene_path != "":
		get_tree().change_scene_to_file(last_scene_path)
	else:
		get_tree().change_scene_to_file(default_path)
