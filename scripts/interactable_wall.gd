extends Area3D

# Damage to decide which place is the best to hide
@export var end_damage := 0.0
# Check if interacted with door
@export var is_door := false
# Check if interacted with wall
@export var is_wall := false

@export var camera_hide_position := Vector3(0.0, 0.3, 0.0)

@onready var game_state := get_node("/root/game_state")

var player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	game_state.earthquake_end.connect(_on_earthquake_end)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		body.set_nearby_spot(self, "")
		
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		body.clear_nearby_spot(self)
		
func _on_earthquake_end()  -> void:
	if get_tree().paused:
		return
	if player == null:
		return
		
	if player.is_hiding and player.current_hide_spot == self:
		var damage = end_damage if not player.is_crawling else end_damage * 0.65
		var new_health = max(player.health - damage, 5.0)
		player.health = new_health
		player.health_bar.value = new_health
		game_state.hiding_damage_applied = true
