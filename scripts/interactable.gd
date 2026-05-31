extends StaticBody3D

@export var hide_label := "Somewhere"
# Distance when shine appears
@export var max_distance := 6.0
# Distance when shine is at max
@export var min_distance := 2.0
# Damage to decide which place is the best to hide
@export var end_damage := 0.0
# Check if interacted with door
@export var is_door := false
# Check if interacted with sofa
@export var is_sofa := false

@export var pillow_path: NodePath

@export var camera_hide_position := Vector3(0.0, 0.3, 0.0)
# Prop trigger zone
@onready var area := $Area3D

var player: Node3D = null
var shader_material: ShaderMaterial = null

func _ready() -> void:
#	To hide
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	game_state.earthquake_end.connect(_on_earthquake_end)
	
#	Shaders
	var mesh = get_parent() as MeshInstance3D
	if mesh:
#		Creates unique material for prop so don't glow together
		mesh.material_overlay = mesh.material_overlay.duplicate()
		shader_material = mesh.material_overlay as ShaderMaterial
	
	player = get_tree().get_first_node_in_group("player")
	
func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
		
	var mesh = get_parent() as MeshInstance3D
	var my_position
	
	if mesh:
		my_position = mesh.global_position
	else:
		my_position = global_position
	
	var dist = my_position.distance_to(player.global_position)
	
#	If player > max_distance, strength = 0, get closer strength slowly becomes 5, clamp makes sure stay in range 0-5
	var strength = 0.0
	if dist < max_distance:
		strength = clamp(
			(1.0 - (dist - min_distance) / (max_distance - min_distance)) * 5.0,
			0.0,
			5.0
		)
		
	shader_material.set_shader_parameter("highlight_strength", strength)
	
func _on_body_entered(body : Node3D) -> void:
	if body.has_method("set_nearby_spot"):
		body.set_nearby_spot(self, hide_label)

func _on_body_exited(body : Node3D) -> void:
	if body.has_method("clear_nearby_spot"):
		body.clear_nearby_spot(self)

func _on_earthquake_end() -> void:
	if player == null:
		return
#	Player hiding -> deal that spot's damage
	if player.is_hiding and player.current_hide_spot == self:
		var damage = end_damage if not player.is_crawling else end_damage * 0.65
		var new_health = max(player.health - damage, 5.0)
		player.health = new_health
		player.health_bar.value = new_health
		var no_cover = get("is_sofa") or get("is_wall")
		if not no_cover:
			player.is_hiding = false
		game_state.hiding_damage_applied = true
		
#	Player out in open & not dropped -> set health to 5
	elif not game_state.hiding_damage_applied and not player.is_hiding and not player.is_crawling:
		player.health = 5.0
		player.health_bar.value = player.health
	
#	Player out in open & dropped -> set health to 15
	elif not game_state.hiding_damage_applied and not player.is_hiding and player.is_crawling:
		player.health = 15.0
		player.health_bar.value = player.health
