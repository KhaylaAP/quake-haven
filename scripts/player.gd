extends CharacterBody3D

var SPEED = 8.0
const JUMP_VELOCITY = 4.5

# Health
var max_health := 100.0
var health := 100
var is_dead := false

var is_hiding := false
var is_crawling := false
var current_hide_spot: Node3D = null

@onready var sprite := $AnimatedSprite3D
@onready var health_bar := $SubViewport/ProgressBar
@onready var controls_hud := $ControlsHUD/Panel

func _ready() -> void:
	if game_state.has_player_pos:
		global_position = game_state.last_player_pos
		health = game_state.last_player_health

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
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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
		if is_hiding:
			_unhide()
#		If near hidding spot
		elif current_hide_spot != null:
			_hide()
		
	if Input.is_action_just_pressed("crawl"):
#		Toggle crawl (E button)
		is_crawling = !is_crawling
#		When crawl become slower
		if is_crawling:
			SPEED = 3.0
		else:
			SPEED = 8.0
	
func _hide() -> void:
	is_hiding = true
	sprite.visible = false

func _unhide() -> void:
	is_hiding = false
#	Make player invisible when hiding
	sprite.visible = true
	
func set_nearby_spot(spot: Node3D, label: String) -> void:
#	Set which propt player is near at
	current_hide_spot = spot
	print("Press F to hide: ", label)
	
func clear_nearby_spot(spot: Node3D) -> void:
#	Clear if in the same spot
	if current_hide_spot == spot:
		current_hide_spot = null
		print("")


func take_damage(amount: float) -> void:
	if is_dead:
		return
	
#	Hiding = no damage
	if is_hiding:
		return
		
#	Crawling = 5 damage
	if is_crawling:
		amount = amount * 0.5
	
	health -= amount
	health_bar.value = health
	print("Health: ", health)
	
	if health <= 0:
		_die()
		
func _die() -> void:
	is_dead = true
	game_state.player_can_move = false
	sprite.play("crawl_left")
	get_tree().call_deferred("change_scene_to_file", "res://scenes/gameover.tscn")
	print("Died")
	
func _show_controls_hint() -> void:
	controls_hud.modulate.a = 1.0
	
	await get_tree().create_timer(5.0).timeout
	
	var tween = create_tween()
	tween.tween_property(controls_hud, "modulate:a", 0.0, 1.5)
	await tween.finished
	controls_hud.visible = false
