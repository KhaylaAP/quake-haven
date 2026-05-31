extends CanvasLayer

@onready var game_state := get_node("/root/game_state")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_tree().paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true

func _on_resume_button_pressed() -> void:
	visible = false
	get_tree().paused = false

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	game_state.player_can_move = false
	game_state.has_player_pos = false
	game_state.was_hiding = false
	game_state.camera_under_table = false
	game_state.camera_angle = 0.0
	game_state.camera_hide_pos = Vector3.ZERO
	game_state.hiding_damage_applied = false
	game_state.earthquake_active = false
	game_state.was_hiding_sofa = false
	get_tree().change_scene_to_file(game_state.LEVEL_PATHS[game_state.current_level])


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	game_state.player_can_move = false
	game_state.has_player_pos = false
	game_state.was_hiding = false
	game_state.camera_under_table = false
	game_state.camera_angle = 0.0
	game_state.camera_hide_pos = Vector3.ZERO
	game_state.hiding_damage_applied = false
	game_state.earthquake_active = false
	game_state.was_hiding_sofa = false
	get_tree().change_scene_to_file("res://scenes/levelselect.tscn")
