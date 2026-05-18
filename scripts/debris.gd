extends RigidBody3D

@export var damage := 10.0

# To make sure only hit once per debris
var has_hit := false
var has_impacted := false

@onready var trail_particles := $TrailParticles
@onready var impact_particles := $ImpactDust
@onready var impact_chunks := $ImpactChunk

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	Random size debris
	var scale_factor = randf_range(1.0, 1.5)
	scale = Vector3(scale_factor, scale_factor, scale_factor)
	
#	Random rotation debris
	rotation = Vector3(
		randf_range(0, PI),
		randf_range(0, PI),
		randf_range(0, PI)
	)
	
#	Random spin debris
	angular_velocity = Vector3(
		randf_range(-5, 5),
		randf_range(-5, 5),
		randf_range(-5, 5)
	)
	
	body_entered.connect(_on_body_entered)
	
#	Delete after 5 seconds
	await get_tree().create_timer(5.0).timeout
	queue_free()
	
func _on_body_entered(body: Node) -> void:
	if has_impacted:
		return
	has_impacted = true
	
	trail_particles.emitting = false
	
	if is_instance_valid(impact_particles):
		impact_particles.reparent(get_tree().current_scene)
		impact_particles.emitting = true
	
	if is_instance_valid(impact_chunks):
		impact_chunks.reparent(get_tree().current_scene)
		impact_chunks.emitting = true
	
	if has_hit:
		return
	if body.has_method("take_damage"):
		has_hit = true
		body.take_damage(damage)
		
	await get_tree().create_timer(impact_particles.lifetime + 0.1).timeout
	impact_particles.queue_free()
	impact_chunks.queue_free()
	
	await get_tree().create_timer(0.1).timeout
	queue_free()
