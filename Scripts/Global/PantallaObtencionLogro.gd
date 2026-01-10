extends Control

@onready var logro_insignia: TextureRect = $LogroInsignia
@onready var label: Label = $Label
@onready var btn_continuar: Button = $btn_continuar

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false

func _ready():
	btn_continuar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_continuar.pressed.connect(_on_continuar_pressed)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	en = load_language_setting()
	if en:
		btn_continuar.text = "Continue"
	else:
		btn_continuar.text = "Continuar"
	_show_next_achievement()

func _show_next_achievement() -> void:
	var achievement_id = Score.pop_next_pending_achievement()
	if achievement_id == "":
		get_tree().change_scene_to_file("res://Escenas/PuntajeScreen.tscn")
		return
	var texture_path = Score.get_achievement_texture_path(achievement_id)
	if texture_path != "":
		logro_insignia.texture = load(texture_path)
	label.text = Score.get_achievement_message(achievement_id, en)
	_start_continue_delay()

func _start_continue_delay() -> void:
	btn_continuar.visible = false
	btn_continuar.disabled = true
	await get_tree().create_timer(2.0).timeout
	btn_continuar.visible = true
	btn_continuar.disabled = false

func _on_continuar_pressed() -> void:
	ButtonClick.button_click()
	if Score.has_pending_achievement():
		_show_next_achievement()
	else:
		get_tree().change_scene_to_file("res://Escenas/PuntajeScreen.tscn")
