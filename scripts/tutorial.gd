extends Node2D

@onready var anim := $AnimationPlayer
@onready var skip_btn := $Button/Skip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	skip_btn.pressed.connect(_finish_tutorial)
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("tutorial")
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		anim.speed_scale = 3.0
	else:
		anim.speed_scale = 1.0

func _on_animation_finished(anim_name: String) -> void:
	_finish_tutorial()
	
func _finish_tutorial() -> void:
	game_state.current_level = 0
	game_state.unlock_next_level()
	get_tree().change_scene_to_file("res://scenes/levelselect.tscn")
