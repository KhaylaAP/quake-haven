extends Area3D

#How much trauma decreases each second
@export var trauma_reduction_rate := 1.0

#Noise to determine how much camera rotates
@export var noise : FastNoiseLite
#Noise to determine how fast camera rotates
@export var noise_speed := 50.0

#Constraint where camera can shake
@export var max_x := 10.0
@export var max_y := 10.0
@export var max_z := 5.0

@export var earthquake_enabled := true

@export var earthquake_duration := 10
@export var debris_min := 10
@export var debris_max := 50

@export var rotate_speed := 90.0

#Shake intensity
var trauma := 0.0

var time := 0.0

var earthquake_active := false

var original_position : Vector3

var intro_done := false

@onready var camera := $Camera3D as Camera3D
@onready var initial_rotation := camera.rotation_degrees as Vector3
# BlackScreen
@onready var black_screen := $CanvasLayer/BlackScreen

@onready var pivot := get_parent()

func _ready() -> void:
	add_to_group("shakeable_camera")
	original_position = position
	camera.position = Vector3.ZERO
	if not earthquake_enabled:
		intro_done = true
		return
	
#	Rotate camera 360
	pivot.rotation_degrees.y = 0.0
	var tween = create_tween()
	tween.tween_property(camera, "rotation_degrees:y", camera.rotation_degrees.y + 360, 5.0)
	await tween.finished
	
	pivot.rotation_degrees.y = 0.0
	intro_done = true
	game_state.player_can_move = true
	
#	Wait 5 seconds before earthquake starts
	await get_tree().create_timer(5.0).timeout
	_start_earthquake(earthquake_duration)

func _process(delta: float) -> void:
	time += delta
	
	if game_state.camera_under_table:
		camera.global_position = camera.global_position.lerp(game_state.camera_hide_pos, delta * 5.0)
	
	if not intro_done:
		return
	
	if earthquake_active:
#		Refill trauma so it doesnt decay
		add_trauma(delta * 1.0)
	else:
	#	Max makes sure var trauma >= 0
		trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and not game_state.camera_under_table:
		if camera.global_position.distance_to(player.global_position) > 0.01:
			camera.look_at(player.global_position)
			initial_rotation = camera.rotation_degrees
	
#	Camera shake
	camera.rotation_degrees.x = initial_rotation.x + max_x * get_shake_intensity() * get_noise_from_seed(0)
	camera.rotation_degrees.y = initial_rotation.y + max_y * get_shake_intensity() * get_noise_from_seed(1)
	camera.rotation_degrees.z = initial_rotation.z + max_z * get_shake_intensity() * get_noise_from_seed(2)
	
func add_trauma(trauma_amount: float):
#	Clamp makes sure trauma in range of 0 - 1
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)

# To make screen intensity curve more dramatic
func get_shake_intensity() -> float:
	return trauma * trauma
	
func get_noise_from_seed(_seed : int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)

func _start_earthquake(duration: float) -> void:
	game_state.hiding_damage_applied = false
	earthquake_active = true
	game_state.earthquake_start.emit()
	await get_tree().create_timer(duration).timeout
	earthquake_active = false
	game_state.earthquake_end.emit()
	game_state.unlock_next_level()
	await _fade_scene(game_state.load_broken())
	
func _fade_scene(scene_path: String) -> void:
	black_screen.visible = true
	
#	Fade in black
	var tween = create_tween()
	tween.tween_property(black_screen, "modulate:a", 1.0, 1.5)
	await tween.finished
	
#	Get player position
	var player = get_tree().get_first_node_in_group("player")
	game_state.last_player_pos = player.global_position
	game_state.last_player_health = player.health
	game_state.has_player_pos = true
	game_state.save_score()
	
#	Reset camera
	game_state.camera_angle = 0.0
	game_state.hiding_damage_applied = false
	game_state.earthquake_active = false
	
#	Change scene
	get_tree().call_deferred("change_scene_to_file", scene_path)
	await get_tree().process_frame
	
#	Fade out of black
	tween = create_tween()
	tween.tween_property(black_screen, "modulate:a", 0.0, 1.5)
	await tween.finished
	
	black_screen.visible = false

func _input(event: InputEvent) -> void:
	if not game_state.player_can_move:
		return
	if Input.is_action_just_pressed("ui_right"):
		_rotate_camera(-90.0)
	elif Input.is_action_just_pressed("ui_left"):
		_rotate_camera(90.0)
		

var rotate_tween: Tween

# Arrow keys to rotate camera
func _rotate_camera(degrees: float) -> void:
	game_state.camera_angle += degrees

	if rotate_tween:
		rotate_tween.kill()
	
	rotate_tween = create_tween()
	rotate_tween.tween_property(pivot, "rotation_degrees:y", game_state.camera_angle, 0.3)


func reset_camera_position() -> void:
	camera.position = Vector3.ZERO
	pivot.rotation_degrees.y = game_state.camera_angle
