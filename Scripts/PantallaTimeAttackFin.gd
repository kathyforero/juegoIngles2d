extends Node2D
# Modal for Time Attack end (no tree pause; music keeps playing)

const NEXT_ICON_EN_PATH := "res://Sprites/buttons/Boton_Next.png"
const NEXT_ICON_ES_PATH := "res://Sprites/buttons/Boton_Next_es.png"

@onready var title_label: Label = $TitleLabel
@onready var stats_label: Label = $StatsLabel
#@onready var record_label: Label = $RecordLabel
@onready var btn_next: Button = $BtnNext

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false

func _ready() -> void:
	en = load_language_setting()

	var levels := int(Score.levels_completed)
	var secs := int(Score.time_attack_seconds)
	# var total := int(Score.latest_total_score) # lo tienes, por si luego lo quieres mostrar

	_apply_language(levels, secs)
	_apply_next_icon()

	btn_next.pressed.connect(_on_next_pressed)
	btn_next.grab_focus()

func _apply_language(levels: int, secs: int) -> void:
	title_label.text = "TURBO MODE OVER!" if en else "¡MODO TURBO TERMINADO!"

	# Mantengo el mismo contenido que ya mostrabas, solo traducido
	if en:
		stats_label.text = "Levels completed: %d\nSelected time: %ds" % [levels, secs]
	else:
		stats_label.text = "Niveles completados: %d\nTiempo seleccionado: %ds" % [levels, secs]

func _apply_next_icon() -> void:
	var path := NEXT_ICON_EN_PATH if en else NEXT_ICON_ES_PATH
	var tex: Texture2D = load(path)
	if tex:
		btn_next.icon = tex
		btn_next.expand_icon = true
		btn_next.flat = true
	else:
		push_warning("PantallaTimeAttackFin: no se pudo cargar icono Next -> %s" % path)

func _on_next_pressed() -> void:
	ButtonClick.button_click()
	if Score.has_pending_achievement():
		get_tree().change_scene_to_file("res://Escenas/Global/PantallaObtencionLogro.tscn")
	else:
		get_tree().change_scene_to_file("res://Escenas/PuntajeScreen.tscn")
