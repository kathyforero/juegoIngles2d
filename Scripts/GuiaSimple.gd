extends Node2D

@export var next_scene_path: String = ""
@export var prev_scene_path: String = ""
@export var title_text: String = ""
@export var content_text: String = ""

@onready var title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var content_label: Label = $ContentLabel if has_node("ContentLabel") else null
@onready var next_button: TextureButton = $SiguienteButton if has_node("SiguienteButton") else null
@onready var prev_button: TextureButton = $RetrocederButton if has_node("RetrocederButton") else null
@onready var exit_button: TextureButton = $SalirButton if has_node("SalirButton") else null

func _ready():
	if title_label:
		title_label.text = title_text if title_text != "" else title_label.text
	if content_label:
		content_label.text = content_text if content_text != "" else content_label.text
	if next_button:
		next_button.visible = next_scene_path != ""
	if prev_button:
		prev_button.visible = prev_scene_path != ""

func _on_siguiente_button_pressed():
	ButtonClick.button_click()
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)

func _on_retroceder_button_pressed():
	ButtonClick.button_click()
	if prev_scene_path != "":
		get_tree().change_scene_to_file(prev_scene_path)

func _on_salir_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_principal.tscn")
