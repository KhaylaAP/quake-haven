extends Area3D

var player_nearby := false
var base_y: float
var bob_speed := 2.0
var bob_height := 0.15

@onready var sprite := $FlagSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_y = global_position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	global_position.y = base_y + sin(t * bob_speed) * bob_height
	var pulse = (sin(t * 3.0) + 1.0) / 2.0
	sprite.modulate = Color(1.0, 1.0, 0.3 + pulse * 0.7, 1.0)
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
	
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
	
func _input(event: InputEvent) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/levelselect.tscn")
