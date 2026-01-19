extends Node2D

var score: int = 0
var bonus: int = 0
var fastBonus: int = 0
var perfectBonus: int = 0
var en: bool = false

var _exit_locked: bool = true
var _reveal_finished: bool = false
var _record_required: bool = false
var _record_saved: bool = false

const BEST_NAME_MAX_LEN := 12

# ---------- Language ----------
func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text := FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return bool(data["english"])
	return false


func update_language_score_screen() -> void:
	# UI nodes in PuntajeScreen.tscn
	var board: Sprite2D = $TextoFelicitaciones
	var lbl_total: Label = $"Tu puntaje"
	var lbl_fast: Label = $"Bonus de velocidad"
	var lbl_perf: Label = $Perfecto
	var btn: Button = $Button

	if en:
		board.texture = load("res://Sprites/global/texto felicitaciones_eng.png")
		lbl_total.text = "Your score"
		lbl_fast.text = "Very Fast"
		lbl_perf.text = "Perfect"
		btn.icon = load("res://Sprites/buttons/Boton_Next.png")
	else:
		board.texture = load("res://Sprites/global/texto felicitaciones.png")
		lbl_total.text = "Tu puntaje"
		lbl_fast.text = "Muy veloz"
		lbl_perf.text = "Perfecto"
		btn.icon = load("res://Sprites/buttons/Boton_Next_es.png")


func _apply_best_name_popup_language() -> void:
	# BestNamePopup.tscn ahora tiene más Labels (TitleLabel, MessageLabel, etc.)
	if not has_node("BestNameDialog"):
		return

	var title := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/TitleLabel")
	var msg := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/MessageLabel")
	var name_lbl := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/NameRow/NameLabel")
	var name_edit := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/NameRow/NameEdit")
	var btn_cancel := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/CancelButton")
	var btn_save := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/SaveButton")
	if btn_save == null:
		btn_save = $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/SaveButton")
	name_edit.max_length = BEST_NAME_MAX_LEN
	if en:
		if title: title.text = "NEW RECORD!"
		if msg: msg.text = "Type your name to save the record."
		if name_lbl: name_lbl.text = "Name:"
		if name_edit:
			name_edit.placeholder_text = "Player"
		if btn_cancel: btn_cancel.text = "Cancel"
		if btn_save: btn_save.text = "Save"
	else:
		if title: title.text = "¡NUEVO RÉCORD!"
		if msg: msg.text = "Escribe tu nombre para guardar el récord."
		if name_lbl: name_lbl.text = "Nombre:"
		if name_edit:
			name_edit.placeholder_text = "Jugador"
		if btn_cancel: btn_cancel.text = "Cancelar"
		if btn_save: btn_save.text = "Guardar"


func _update_performance_texts() -> void:
	# Solo ajusta los textos si el performance fue bajo; si fue bueno, dejamos los textos base.
	# Perfect bonus
	if Score.perfectBonus < 80:
		$Perfecto.text = "Good job" if en else "Buen trabajo"
	elif Score.perfectBonus < 100:
		$Perfecto.text = "Almost perfect" if en else "Casi perfecto"
	# else: queda "Perfect/Perfecto" del idioma base

	# Speed bonus (si existe y está visible)
	if has_node("Bonus de velocidad") and $"Bonus de velocidad".visible:
		if Score.fastBonus < 80:
			$"Bonus de velocidad".text = "Fast" if en else "Veloz"
		# else: queda "Very Fast/Muy veloz" del idioma base


# ---------- Popup wiring (BestNamePopup.tscn changed: SaveButton2) ----------
func _wire_best_name_popup() -> void:
	if not has_node("BestNameDialog"):
		return

	var cancel_btn := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/CancelButton")
	var save_btn := $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/SaveButton")
	if save_btn == null:
		save_btn = $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/SaveButton")

	# Conectar sin duplicar (por si ya hay conexiones desde el .tscn)
	if cancel_btn != null:
		var ccall := Callable(self, "_on_BestNameDialog_cancelled")
		if not cancel_btn.pressed.is_connected(ccall):
			cancel_btn.pressed.connect(ccall)

	if save_btn != null:
		var scall := Callable(self, "_on_BestNameDialog_confirmed")
		if not save_btn.pressed.is_connected(scall):
			save_btn.pressed.connect(scall)


# ---------- New Record badge ----------
func _set_new_record_visible(v: bool) -> void:
	if has_node("NewBestLabel"):
		$NewBestLabel.visible = v
	if has_node("NewBestFrame"):
		$NewBestFrame.visible = v


func _set_new_record_text() -> void:
	# Label en la escena está pensado en 2 líneas
	if not has_node("NewBestLabel"):
		return
	$NewBestLabel.text = "NEW\nRECORD!" if en else "NUEVO\nRÉCORD!"

func _set_exit_locked(v: bool) -> void:
	_exit_locked = v
	if has_node("Button"):
		$Button.disabled = v
		# opcional: si quieres que no “tiente” al jugador visualmente
		# $Button.visible = not v

func _unlock_exit_if_ready() -> void:
	# Solo se puede salir cuando:
	# - el puntaje ya terminó de mostrarse
	# - y si hubo record, ya guardó nombre
	if not _reveal_finished:
		return
	if _record_required and not _record_saved:
		return
	_set_exit_locked(false)


# ---------- Lifecycle ----------
func _ready():
	if Score.is_practice():
		# En Practice jamás deberíamos caer aquí.
		get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")
		return

	en = load_language_setting()
	update_language_score_screen()
	_apply_best_name_popup_language()
	_update_performance_texts()

	_wire_best_name_popup()

	# Por defecto ocultamos el badge (en tu .tscn el frame estaba visible)
	_set_new_record_visible(false)

	# Si es Time Attack, ocultamos velocidad (porque se quita ese bonus)
	if Score.current_mode == Score.Mode.TIME_ATTACK:
		if has_node("Bonus de velocidad"):
			$"Bonus de velocidad".visible = false
		if has_node("Puntaje2"):
			$Puntaje2.visible = false

	# Evitar mensaje engañoso:
	# Solo mostramos "NEW RECORD" si este score quedará como best-of-both en PantallaPuntajes
	if Score.is_new_best and not _will_be_best_of_both_for_this_run():
		Score.is_new_best = false
		
	# Bloquear salida hasta que se muestre todo el puntaje (y se guarde nombre si hay récord)
	_set_exit_locked(true)
	_reveal_finished = false
	_record_required = false
	_record_saved = false
	
	# Arrancar animación de conteo
	updateScore()

	# Valores base visibles
	score = 0
	fastBonus = 0
	perfectBonus = 0


func _process(_delta):
	$Puntaje.text = str(score)

	# Si es Time Attack, Puntaje2 está oculto. Igual lo protegemos.
	if has_node("Puntaje2") and $Puntaje2.visible:
		$Puntaje2.text = "+" + str(fastBonus)

	$Puntaje3.text = "+" + str(perfectBonus)


# ---------- Score counting ----------
func updateScore():
	bonus = int(Score.fastBonus) + int(Score.perfectBonus)

	await get_tree().create_timer(1).timeout

	var tempScore := score

	# 1) Base score
	var target_score := tempScore + int(Score.newScore)
	if score < target_score:
		$AudioStreamPlayer2D.play(0.0)
		while score < target_score:
			await get_tree().create_timer(0.01).timeout
			score = min(score + 5, target_score)
		$AudioStreamPlayer2D.stop()

	# 2) Fast bonus (si aplica)
	await get_tree().create_timer(0.8).timeout
	if fastBonus < int(Score.fastBonus):
		$AudioStreamPlayer2D.play(0.0)
		while fastBonus < int(Score.fastBonus):
			await get_tree().create_timer(0.01).timeout
			fastBonus = min(fastBonus + 5, int(Score.fastBonus))
		$AudioStreamPlayer2D.stop()

	# 3) Perfect bonus
	await get_tree().create_timer(0.8).timeout
	if perfectBonus < int(Score.perfectBonus):
		$AudioStreamPlayer2D.play(0.0)
		while perfectBonus < int(Score.perfectBonus):
			await get_tree().create_timer(0.01).timeout
			perfectBonus = min(perfectBonus + 5, int(Score.perfectBonus))
		$AudioStreamPlayer2D.stop()

	# 4) Total (base + bonus)
	await get_tree().create_timer(0.5).timeout
	var target_total := tempScore + int(Score.newScore) + bonus
	if score < target_total:
		$AudioStreamPlayer2D.play(0.0)
		while score < target_total:
			await get_tree().create_timer(0.01).timeout
			score = min(score + 5, target_total)
		$AudioStreamPlayer2D.stop()
	# Ya terminó el “reveal” del puntaje
	_reveal_finished = true

	# NEW RECORD popup (solo si aplica)
	if Score.is_new_best:
		_record_required = true
		_record_saved = false

		_set_new_record_text()
		_set_new_record_visible(true)

		await get_tree().create_timer(0.6).timeout

		# Mostrar popup
		$BestNameDialog.visible = true

		# 🔒 No permitir “Cancelar” (para que no lo esquiven)
		var cancel_btn = $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/ButtonsRow/CancelButton")
		if cancel_btn:
			cancel_btn.visible = false
			cancel_btn.disabled = true

		var name_edit = $BestNameDialog/CenterContainer/Panel/MarginContainer/VBox/NameRow/NameEdit
		name_edit.text = ""
		name_edit.grab_focus()

		# Seguimos bloqueados hasta que guarde nombre
		_set_exit_locked(true)
	else:
		_record_required = false
		_record_saved = true  # no aplica
		_set_new_record_visible(false)

		# ✅ Ya puede salir porque ya se mostró todo
		_unlock_exit_if_ready()


# ---------- Record file helpers ----------
func _get_score_file_path() -> String:
	var base = Global.rutaArchivos + "/Scores/"
	match Score.LatestGame:
		Score.Games.Puzzle:
			return base + "puntajesPuzzle.dat"
		Score.Games.MatchIt:
			return base + "puntajesMatch.dat"
		Score.Games.OrderIt:
			return base + "puntajesOrder.dat"
		_:
			return ""


func _get_total_from_dict(puntajes: Dictionary, diff: String) -> int:
	if not puntajes.has(diff):
		return 0
	var d = puntajes[diff]
	if d.has("best_score"):
		return int(d["best_score"])
	var v := int(d.get("velocidad", 0))
	var p := int(d.get("precision", 0))
	var n := int(d.get("niveles", 0))
	return v + p + n


func _will_be_best_of_both_for_this_run() -> bool:
	# Regla: solo mostrar "NEW RECORD" si este score va a quedar como el que muestra PantallaPuntajes (best-of-both)
	var path := _get_score_file_path()
	if path == "" or not FileAccess.file_exists(path):
		# si el archivo no existe, cualquier récord nuevo será global por definición
		return true

	var file := FileAccess.open(path, FileAccess.READ)
	var raw = file.get_var()
	file.close()

	if typeof(raw) != TYPE_DICTIONARY:
		return true

	var diff := str(Score.actualDifficult)

	# NORMAL en raíz
	var normal_best := _get_total_from_dict(raw, diff)

	# TIME ATTACK en rama "time_attack"
	var ta_dict: Dictionary = raw.get("time_attack", {})
	var ta_best := _get_total_from_dict(ta_dict, diff)

	var my_score := int(Score.latest_total_score)

	if Score.is_time_attack():
		# PantallaPuntajes prefiere NORMAL en empate,
		# así que Turbo SOLO se verá si es ESTRICTAMENTE mayor que Normal.
		return my_score > normal_best
	else:
		# Classic sí se verá si supera o empata al Turbo (porque empate favorece Normal)
		return my_score >= ta_best


func _save_best_name(player_name: String) -> void:
	var path := _get_score_file_path()
	if path == "" or not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return

	var diff_key = Score.actualDifficult  # "easy" / "medium" / "hard"

	if Score.current_mode == Score.Mode.TIME_ATTACK:
		if not data.has("time_attack"):
			data["time_attack"] = {}

		# asegurar las 3 dificultades
		for d in ["easy", "medium", "hard"]:
			if not data["time_attack"].has(d):
				data["time_attack"][d] = {"best_score": 0, "name": "---", "levels": 0, "seconds": 0, "precision": 0}

		if not data["time_attack"].has(diff_key):
			data["time_attack"][diff_key] = {"best_score": 0, "name": "---", "levels": 0, "seconds": 0, "precision": 0}

		data["time_attack"][diff_key]["name"] = player_name
	else:
		# Clásico (tu formato original)
		if not data.has(diff_key):
			return
		data[diff_key]["name"] = player_name

	var filew := FileAccess.open(path, FileAccess.WRITE)
	filew.store_var(data)
	filew.close()


# ---------- UI callbacks ----------
func _on_BestNameDialog_confirmed():
	var name_edit = $BestNameDialog/CenterContainer/Panel/MarginContainer/VBox/NameRow/NameEdit
	var name = name_edit.text.strip_edges()
	if name.length() > BEST_NAME_MAX_LEN:
		name = name.substr(0, BEST_NAME_MAX_LEN)

	if name == "":
		name = "Player" if en else "Jugador"

	_save_best_name(name)

	$BestNameDialog.visible = false
	_record_saved = true

	# ✅ ya puede salir (porque ya vio el puntaje + guardó nombre)
	_unlock_exit_if_ready()


func _on_BestNameDialog_cancelled():
	# No permitir cerrar sin guardar cuando es récord
	if _record_required and not _record_saved:
		# lo devolvemos al input (modo: “no te me vas” 😄)
		var name_edit = $BestNameDialog.get_node_or_null("CenterContainer/Panel/MarginContainer/VBox/NameRow/NameEdit")
		if name_edit:
			name_edit.grab_focus()
		return

	$BestNameDialog.visible = false


func _on_button_pressed():
	if _exit_locked:
		return

	ButtonClick.button_click()
	Score.is_new_best = false
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")
