extends Node2D

const SUBJECTS := [
	"El nino",
	"La nina",
	"El estudiante",
	"La maestra",
	"El medico",
	"La familia",
	"El equipo",
	"Mi amiga",
	"El cientifico",
	"La exploradora"
]
const VERBS := [
	"corre",
	"salta",
	"lee",
	"escribe",
	"juega",
	"baila",
	"canta",
	"conduce",
	"explora",
	"observa"
]
const PREDICATES := [
	"en el parque",
	"en la escuela",
	"en casa",
	"en el laboratorio",
	"en el museo",
	"en la ciudad",
	"en el escenario",
	"en el jardin",
	"en la biblioteca",
	"en la playa"
]

var rng := RandomNumberGenerator.new()

@export var next_scene_path: String = ""
@export var prev_scene_path: String = ""
@export var title_text: String = ""
@export var content_text: String = ""

@onready var title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var content_label: Label = $ContentLabel if has_node("ContentLabel") else null
@onready var next_button: TextureButton = $SiguienteButton if has_node("SiguienteButton") else null
@onready var prev_button: TextureButton = $RetrocederButton if has_node("RetrocederButton") else null
@onready var exit_button: TextureButton = $SalirButton if has_node("SalirButton") else null
@onready var generate_button: TextureButton = $SalirButton2 if has_node("SalirButton2") else null
@onready var subject_label: Label = $Sujeto_txt if has_node("Sujeto_txt") else null
@onready var verb_label: Label = $Verbo_txt if has_node("Verbo_txt") else null
@onready var predicate_label: Label = $Predicado_txt if has_node("Predicado_txt") else null

func _ready():
	rng.randomize()
	if title_label:
		title_label.text = title_text if title_text != "" else title_label.text
	if content_label:
		content_label.text = content_text if content_text != "" else content_label.text
	if next_button:
		next_button.visible = next_scene_path != ""
	if prev_button:
		prev_button.visible = prev_scene_path != ""
	if generate_button:
		generate_button.pressed.connect(_on_generate_button_pressed)
	if subject_label and verb_label and predicate_label:
		_generate_sentence()

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

func _on_generate_button_pressed():
	ButtonClick.button_click()
	_generate_sentence()

func _generate_sentence():
	if not subject_label or not verb_label or not predicate_label:
		return
	subject_label.text = SUBJECTS[_rand_index(SUBJECTS)]
	verb_label.text = VERBS[_rand_index(VERBS)]
	predicate_label.text = PREDICATES[_rand_index(PREDICATES)]

func _rand_index(list):
	return rng.randi_range(0, max(list.size() - 1, 0))
