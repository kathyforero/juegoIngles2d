extends Node2D

var occupied: bool = false
var current_area: Area2D = null
@export var letter: String = "A"

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func setLetter(letra: String) -> void:
	letter = letra

func _has_prop(obj: Object, prop: String) -> bool:
	if obj == null:
		return false
	for p in obj.get_property_list():
		# get_property_list returns Dictionaries with a "name" key
		if typeof(p) == TYPE_DICTIONARY and p.has("name") and String(p["name"]) == prop:
			return true
	return false

func _is_letter_piece_area(area: Area2D) -> bool:
	if area == null:
		return false
	var parent := area.get_parent()
	# Letters are Node2D with script vars: snap_to, target_letter
	return parent != null and _has_prop(parent, "snap_to") and _has_prop(parent, "target_letter")

func _on_area_2d_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	# Ignore overlaps between Letterboxes (their Area2D also collides) or any other Area2D not belonging to a Letter piece.
	if occupied:
		return
	if not _is_letter_piece_area(area):
		return

	occupied = true
	current_area = area

	var piece := area.get_parent()
	# Use global coordinates because the letter drags using get_global_mouse_position()
	piece.snap_to = global_position
	piece.target_letter = letter

func hint() -> void:
	$AnimationPlayer.play("Hint")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area == current_area:
		occupied = false
		current_area = null
