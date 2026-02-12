extends Node2D

const SUBJECTS := [
	"The boy",
	"The girl",
	"The student",
	"The teacher",
	"The doctor",
	"The family",
	"The team",
	"My friend",
	"The scientist",
	"The explorer"
]

const VERBS := [
	"runs",
	"jumps",
	"reads",
	"writes",
	"plays",
	"dances",
	"sings",
	"paints",
	"explores",
	"observes"
]

const PREDICATES := [
	"in the park",
	"at school",
	"at home",
	"in the laboratory",
	"in the museum",
	"in the city",
	"in the garden",
	"in the library",
	"on the beach",
	"in the coliseum",
	"in the stadium"
]

const MAX_CARDS := 9

const CATEGORY_DATA_PATH := "res://JsonJuegos/CardLabels.json"
const FALLBACK_CATEGORY_DEFINITIONS := []
var category_definitions := FALLBACK_CATEGORY_DEFINITIONS.duplicate()

var rng := RandomNumberGenerator.new()
var card_defaults := {}
var category_button_defaults := {}
var selected_category_index := -1
var current_card_label_texts := []
var last_pressed_card := -1
var card_texture_defaults := {}
var current_category_page := 0
var current_category_pages := 1

const CARD_PRESSED_TEXTURE := preload("res://Sprites/global/cards_pressed.png")

@export var next_scene_path: String = ""
@export var prev_scene_path: String = ""
@export var title_text: String = ""
@export var content_text: String = ""

var en := false

@onready var title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var title_label_2: Label = $TitleLabel2 if has_node("TitleLabel2") else null
@onready var content_label: Label = $ContentLabel if has_node("ContentLabel") else null
@onready var next_button: TextureButton = $SiguienteButton if has_node("SiguienteButton") else null
@onready var prev_button: TextureButton = $RetrocederButton if has_node("RetrocederButton") else null
@onready var exit_button: TextureButton = $SalirButton if has_node("SalirButton") else null
@onready var generate_button: TextureButton = $SalirButton2 if has_node("SalirButton2") else null
@onready var subject_label: Label = $Sujeto_txt if has_node("Sujeto_txt") else null
@onready var verb_label: Label = $Verbo_txt if has_node("Verbo_txt") else null
@onready var predicate_label: Label = $Predicado_txt if has_node("Predicado_txt") else null
@onready var description_label: Label = $Label4 if has_node("Label4") else null
@onready var subject_title_label: Label = $Sujeto if has_node("Sujeto") else null
@onready var verb_title_label: Label = $Verbo if has_node("Verbo") else null
@onready var predicate_title_label: Label = $Predicado if has_node("Predicado") else null
@onready var generate_label: Label = $Boton if has_node("Boton") else null
@onready var pagination_prev_button: TextureButton = $Retroceder if has_node("Retroceder") else null
@onready var pagination_next_button: TextureButton = $Avanzar if has_node("Avanzar") else null
@onready var pagination_page_label: Label = $PaginaLabel if has_node("PaginaLabel") else null

func load_language_setting() -> bool:
	if FileAccess.file_exists("user://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("user://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false

func _update_language_texts():
	var spanish_description := "La sintaxis es el orden de las palabras:\nQUIEN + HACE QUE + ¿EN DÓNDE?\nEjemplo: \"El niño juega en la playa\"\nEl niño (quien) -> Juega (que) -> en la playa (en dónde)"
	if title_label:
		title_label.text = "Syntax" if en else "Sintaxis"
	if title_label_2:
		title_label_2.text = "Vocabulary" if en else "Vocabulario"
	if description_label:
		# Always keep the guide explanation in Spanish so it never translates.
		description_label.text = spanish_description
	if subject_title_label:
		subject_title_label.text = "Subject" if en else "Sujeto"
	if verb_title_label:
		verb_title_label.text = "Verb" if en else "Verbo"
	if predicate_title_label:
		predicate_title_label.text = "Predicate" if en else "Predicado"
	if generate_label:
		generate_label.text = "Generate" if en else "Generar"

func _ready():
	rng.randomize()
	en = load_language_setting()
	_load_card_labels()
	if title_label:
		title_label.text = title_text if title_text != "" else title_label.text
	if content_label:
		content_label.text = content_text if content_text != "" else content_label.text
	if next_button:
		next_button.visible = next_scene_path != ""
	if prev_button:
		prev_button.visible = prev_scene_path != ""
	var generate_handler = Callable(self, "_on_generate_button_pressed")
	if generate_button and not generate_button.is_connected("pressed", generate_handler):
		generate_button.connect("pressed", generate_handler)
	if subject_label and verb_label and predicate_label:
		_generate_sentence()
	_setup_category_system()
	_init_pagination_controls()
	_update_language_texts()

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

func _load_card_labels():
	var file = FileAccess.open(CATEGORY_DATA_PATH, FileAccess.READ)
	if not file:
		category_definitions = FALLBACK_CATEGORY_DEFINITIONS.duplicate()
		return
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) != OK:
		category_definitions = FALLBACK_CATEGORY_DEFINITIONS.duplicate()
		return
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		category_definitions = FALLBACK_CATEGORY_DEFINITIONS.duplicate()
		return
	var raw_categories = data.get("categories", null)
	if raw_categories and typeof(raw_categories) == TYPE_ARRAY:
		category_definitions = raw_categories.duplicate()
	else:
		category_definitions = FALLBACK_CATEGORY_DEFINITIONS.duplicate()

func _setup_category_system():
	if category_definitions.size() == 0:
		category_definitions = FALLBACK_CATEGORY_DEFINITIONS.duplicate()
	if not _has_category_buttons():
		return
	_record_card_defaults()
	_init_category_buttons()
	_init_card_interactions()
	_update_category_tags()
	_apply_category(0)

func _init_pagination_controls():
	var prev_handler = Callable(self, "_on_pagination_prev_pressed")
	if pagination_prev_button and not pagination_prev_button.is_connected("pressed", prev_handler):
		pagination_prev_button.connect("pressed", prev_handler)
	var next_handler = Callable(self, "_on_pagination_next_pressed")
	if pagination_next_button and not pagination_next_button.is_connected("pressed", next_handler):
		pagination_next_button.connect("pressed", next_handler)
	_update_pagination_buttons()

func _update_pagination_buttons():
	var show_navigation = current_category_pages > 1
	if pagination_prev_button:
		pagination_prev_button.visible = show_navigation
		pagination_prev_button.disabled = current_category_page <= 0
	if pagination_next_button:
		pagination_next_button.visible = show_navigation
		pagination_next_button.disabled = current_category_page >= current_category_pages - 1
	if pagination_page_label:
		pagination_page_label.visible = current_category_pages > 0
		if current_category_pages > 0:
			pagination_page_label.text = "%d / %d" % [current_category_page + 1, current_category_pages]
		else:
			pagination_page_label.text = ""

func _on_pagination_prev_pressed():
	if current_category_page <= 0:
		return
	current_category_page -= 1
	_refresh_current_category_page()

func _on_pagination_next_pressed():
	if current_category_page >= current_category_pages - 1:
		return
	current_category_page += 1
	_refresh_current_category_page()

func _has_category_buttons() -> bool:
	return has_node("Categoria1")

func _init_category_buttons():
	var index := 0
	while true:
		var button_name = "Categoria%d" % (index + 1)
		if not has_node(button_name):
			break
		var button = get_node(button_name)
		category_button_defaults[button_name] = button.texture_normal
		if index < category_definitions.size():
			button.disabled = false
			var handler = Callable(self, "_on_category_pressed").bind(index)
			if not button.is_connected("pressed", handler):
				button.connect("pressed", handler)
		else:
			button.disabled = true
		index += 1

func _init_card_interactions():
	for i in range(1, MAX_CARDS + 1):
		var card = _get_card_node(i)
		if not card:
			continue
		if not card_texture_defaults.has(card.name):
			card_texture_defaults[card.name] = card.texture_normal
		if CARD_PRESSED_TEXTURE:
			card.texture_pressed = CARD_PRESSED_TEXTURE
		var sprite = _get_card_sprite(i)
		if sprite:
			sprite.visible = false
		var label = _get_card_label(i)
		if label:
			label.visible = false
		var handler = Callable(self, "_on_card_pressed").bind(i)
		if not card.is_connected("pressed", handler):
			card.connect("pressed", handler)

func _update_category_tags():
	var index := 0
	while true:
		var button_name = "Categoria%d" % (index + 1)
		if not has_node(button_name):
			break
		var button = get_node(button_name)
		if not button.has_node("Tag1"):
			index += 1
			continue
		var label = button.get_node("Tag1")
		if label and label is Label:
			if index < category_definitions.size():
				label.text = _get_category_label(category_definitions[index])
			else:
				label.text = ""
		index += 1

func _on_category_pressed(index):
	_apply_category(index)

func _apply_category(index):
	if index < 0 or index >= category_definitions.size():
		return
	selected_category_index = index
	current_category_page = 0
	last_pressed_card = -1
	_update_category_selection(index)
	_refresh_current_category_page()

func _get_category_definition(index):
	if index < 0 or index >= category_definitions.size():
		return null
	return category_definitions[index]

func _refresh_current_category_page():
	var entry = _get_category_definition(selected_category_index)
	if not entry:
		return
	var sprites = entry.get("sprites", [])
	var cards = entry.get("cards", [])
	var total_entries = max(sprites.size(), cards.size())
	current_category_pages = max(1, int((total_entries + MAX_CARDS - 1) / MAX_CARDS)) if total_entries > 0 else 1
	current_category_page = clamp(current_category_page, 0, current_category_pages - 1)
	var page_start = current_category_page * MAX_CARDS
	current_card_label_texts.clear()
	for card_index in range(1, MAX_CARDS + 1):
		var entry_index = page_start + card_index - 1
		var sprite = _get_card_sprite(card_index)
		var label = _get_card_label(card_index)
		var entry_text = ""
		var texture_path = ""
		if entry_index < total_entries:
			_set_card_visibility(card_index, true)
			if entry_index < sprites.size():
				texture_path = sprites[entry_index]
			if entry_index < cards.size():
				entry_text = cards[entry_index]
			if entry_text == "" and texture_path != "":
				entry_text = _derive_label_from_path(texture_path)
			current_card_label_texts.append(entry_text)
			if sprite:
				sprite.visible = true
				if texture_path != "":
					sprite.texture = load(texture_path)
				else:
					sprite.texture = null
				_match_card_image(sprite, card_index)
			if label:
				label.text = entry_text
				label.visible = false
			_set_card_pressed_state(card_index, false)
		else:
			_set_card_visibility(card_index, false)
			if sprite:
				sprite.visible = false
			if label:
				label.visible = false
			current_card_label_texts.append("")
			_set_card_pressed_state(card_index, false)
	_update_pagination_buttons()
func _on_card_pressed(card_index):
	if last_pressed_card != -1 and last_pressed_card != card_index:
		_restore_card(last_pressed_card)
	var sprite = _get_card_sprite(card_index)
	var label = _get_card_label(card_index)
	if sprite:
		sprite.visible = false
	if label:
		label.visible = true
		var text_index = card_index - 1
		if text_index >= 0 and text_index < current_card_label_texts.size():
			label.text = current_card_label_texts[text_index]
	last_pressed_card = card_index
	_set_card_pressed_state(card_index, true)

func _match_card_image(sprite: Sprite2D, card_index: int):
	var card_name = "Card%d" % card_index
	var defaults = card_defaults.get(card_name, null)
	if not defaults:
		var card_node = get_node_or_null(card_name)
		if card_node and card_node is Control:
			sprite.centered = true
			sprite.scale = Vector2.ONE
			sprite.position = card_node.get_size() * 0.5
		return
	sprite.centered = defaults.centered
	sprite.position = defaults.position
	var texture = sprite.texture
	if texture:
		var texture_size = texture.get_size()
		if texture_size.x > 0 and texture_size.y > 0 and defaults.display_size.x > 0 and defaults.display_size.y > 0:
			sprite.scale = Vector2(
				defaults.display_size.x / texture_size.x,
				defaults.display_size.y / texture_size.y
			)
		else:
			sprite.scale = defaults.scale
	else:
		sprite.scale = defaults.scale

func _record_card_defaults():
	for card_index in range(1, MAX_CARDS + 1):
		var sprite = _get_card_sprite(card_index)
		if not sprite:
			continue
		var texture = sprite.texture
		var display_size = Vector2.ZERO
		if texture:
			var texture_size = texture.get_size()
			display_size = Vector2(
				texture_size.x * sprite.scale.x,
				texture_size.y * sprite.scale.y
			) if texture_size.x > 0 and texture_size.y > 0 else Vector2.ZERO
		card_defaults["Card%d" % card_index] = {
			"scale": sprite.scale,
			"position": sprite.position,
			"centered": sprite.centered,
			"display_size": display_size
		}

func _get_card_sprite(card_index):
	var card_name = "Card%d" % card_index
	if not has_node(card_name):
		return null
	var card_node = get_node(card_name)
	if not card_node.has_node("imagen"):
		return null
	var sprite = card_node.get_node("imagen")
	return sprite if sprite is Sprite2D else null

func _get_card_label(card_index):
	var card_node = _get_card_node(card_index)
	if not card_node:
		return null
	var label = card_node.get_node_or_null("Tag1")
	return label if label and label is Label else null

func _get_card_node(card_index):
	var card_name = "Card%d" % card_index
	var node = get_node_or_null(card_name)
	return node if node and node is Control else null

func _set_card_visibility(card_index, visible):
	var card_node = _get_card_node(card_index)
	if not card_node:
		return
	card_node.visible = visible

func _set_card_pressed_state(card_index, pressed):
	var card = _get_card_node(card_index)
	if not card:
		return
	var default_texture = card_texture_defaults.get(card.name, null)
	if pressed and CARD_PRESSED_TEXTURE:
		card.texture_normal = CARD_PRESSED_TEXTURE
	elif default_texture:
		card.texture_normal = default_texture
func _restore_card(card_index):
	if card_index < 1 or card_index > MAX_CARDS:
		return
	var sprite = _get_card_sprite(card_index)
	var label = _get_card_label(card_index)
	if sprite:
		sprite.visible = true
	if label:
		label.visible = false
	_set_card_pressed_state(card_index, false)

func _derive_label_from_path(sprite_path):
	var name = sprite_path.get_file().get_basename()
	name = name.replace("_", " ").replace("-", " ")
	return name.capitalize()

func _update_category_selection(index):
	selected_category_index = index
	var i := 0
	while true:
		var button_name = "Categoria%d" % (i + 1)
		if not has_node(button_name):
			break
		var button = get_node(button_name)
		var default_normal = category_button_defaults.get(button_name, null)
		if i == index:
			if button.texture_hover:
				button.texture_normal = button.texture_hover
		elif default_normal:
			button.texture_normal = default_normal
		i += 1

func _get_category_label(entry: Dictionary) -> String:
	if en and entry.has("label_en"):
		return entry.get("label_en", "")
	return entry.get("label", "")
