extends CharacterBody3D

var SPEED = 8.0
const JUMP_VELOCITY = 5.5

# Health
var max_health := 100.0
var health := max_health
var is_dead := false

var is_hiding := false
var is_crawling := false
var current_hide_spot: Node3D = null

@onready var sprite := $AnimatedSprite3D
@onready var health_bar := $HealthBar2/ProgressBar
@onready var controls_hud := $ControlsHUD/Panel
@onready var hit_particles := $GPUParticles3D

func _ready() -> void:
	if game_state.has_player_pos:
		global_position = game_state.last_player_pos
		health = game_state.last_player_health
	
	if game_state.was_hiding:
		is_hiding = true
		if game_state.was_hiding_sofa or game_state.was_hiding_wall:
			sprite.visible = true
			sprite.play("crawl_right")
		else:
			sprite.visible = false

	add_to_group("player")
	health_bar.max_value = max_health
	health_bar.value = health
	_show_controls_hint()

func _physics_process(delta: float) -> void:
#	Hiding condition & Camera moving = cannot move
	if not game_state.player_can_move or is_hiding or is_dead:
		velocity = Vector3.ZERO
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

#	Input changes based on camera 
	var angle_rad := deg_to_rad(-game_state.camera_angle)
	var rotated_input := Vector2(
		input_dir.x * cos(angle_rad) - input_dir.y * sin(angle_rad),
		input_dir.x * sin(angle_rad) + input_dir.y * cos(angle_rad)
	)
	
	var direction := Vector3(rotated_input.x, 0, rotated_input.y).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_update_animation(input_dir)
	
# Change animation based on direction
func _update_animation(input_dir: Vector2) -> void:
#	Walk animation
	if not is_crawling:
		if input_dir == Vector2.ZERO:
			sprite.play("idle")
		elif input_dir.x < 0:
			sprite.play("walk_right")
		elif input_dir.x > 0:
			sprite.play("walk_left")
		elif input_dir.y < 0:
			sprite.play("walk_front")
		elif input_dir.y > 0:
			sprite.play("walk_back")
#	Crawl animation
	else:
		if input_dir == Vector2.ZERO:
			sprite.play("crawl_idle")
		elif input_dir.x < 0:
			sprite.play("crawl_right")
		elif input_dir.x > 0:
			sprite.play("crawl_left")
		elif input_dir.y < 0:
			sprite.play("crawl_front")
		elif input_dir.y > 0:
			sprite.play("crawl_back")
		
# Hide & unhide interation
func _input(event: InputEvent) -> void:
#	Dont move during camera rotation
	if not game_state.player_can_move:
		return
		
	if Input.is_action_just_pressed("interact"):
		if current_hide_spot != null and current_hide_spot.get("is_door"):
			get_tree().change_scene_to_file("res://scenes/gameover.tscn")
			return
			
		if is_hiding:
			_unhide()
#		If near hidding spot
		elif current_hide_spot != null:
			_hide()
		
	if Input.is_action_just_pressed("crawl"):
#		Toggle crawl (E button)
		is_crawling = !is_crawling
#		When crawl becomes slower
		if is_crawling:
			SPEED = 3.0
		else:
			SPEED = 8.0
	
func _hide() -> void:
	is_hiding = true
	game_state.was_hiding = true
	
	if current_hide_spot.get("is_sofa"):
		sprite.visible = true
		sprite.play("crawl_right")
		game_state.was_hiding_sofa = true
		
		var sofa_pos = current_hide_spot.global_position
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "global_position", Vector3(sofa_pos.x, global_position.y + 0.15, sofa_pos.z), 0.3)
		
		var pillow = current_hide_spot.get_node(current_hide_spot.pillow_path)
		tween.tween_property(pillow, "global_position", Vector3(sofa_pos.x, sofa_pos.y + 1.5, sofa_pos.z), 0.3)
		return
	
	if current_hide_spot.get("is_wall"):
		sprite.visible = true
		sprite.play("crawl_right")
		game_state.was_hiding = true
		game_state.was_hiding_wall = true
		return
	
	sprite.visible = false
	game_state.camera_under_table = true
	game_state.camera_hide_pos = current_hide_spot.global_position + current_hide_spot.camera_hide_position

func _unhide() -> void:
	is_hiding = false
#	Make player invisible when hiding under table
	sprite.visible = true
	game_state.was_hiding = false
	game_state.was_hiding_sofa = false
	game_state.was_hiding_wall = false
	game_state.camera_under_table = false
	
	var cam = get_tree().get_first_node_in_group("shakeable_camera")
	if cam:
		cam.reset_camera_position()
	
	var pivot = get_node("pivot")
	if pivot:
		var tween = create_tween()
		tween.tween_property(pivot, "rotation_degrees:y", game_state.camera_angle, 0.3)
	
	if current_hide_spot != null and current_hide_spot.get("is_sofa"):
		var pillow = current_hide_spot.get_node(current_hide_spot.pillow_path)
		var tween = create_tween()
		tween.tween_property(pillow, "global_position", current_hide_spot.global_position + Vector3(0, 0.6, 0), 0.3)
		sprite.play('idle')
	
func set_nearby_spot(spot: Node3D, label: String) -> void:
#	Set which prop player is near at
	current_hide_spot = spot
	
func clear_nearby_spot(spot: Node3D) -> void:
#	Clear if in the same spot
	if current_hide_spot == spot:
		current_hide_spot = null

func take_damage(amount: float) -> void:
	if is_dead:
		return
	
#	If hiding, don't take damage
	if is_hiding:
		return
		
#	Crawling = 5 damage
	if is_crawling:
		amount = amount * 0.5
	
	health -= amount
	health_bar.value = health
	
	_flash_damage()
	
	if health <= 0:
		_die()
		
func _die() -> void:
	is_dead = true
	game_state.player_can_move = false
	sprite.play("crawl_left")
	get_tree().call_deferred("change_scene_to_file", "res://scenes/gameover.tscn")
	
func _show_controls_hint() -> void:
	controls_hud.modulate.a = 1.0
	
	await get_tree().create_timer(10.0).timeout
	
	var tween = create_tween()
	tween.tween_property(controls_hud, "modulate:a", 0.0, 1.5)
	await tween.finished
	controls_hud.visible = false

func _flash_damage() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.3)
	
	hit_particles.restart()
