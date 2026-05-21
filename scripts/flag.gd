extends Area3D

var player_nearby := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
	
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
	
func _input(event: InputEvent) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/levelselect.tscn")
