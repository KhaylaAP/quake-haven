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


@onready var camera := $Camera3D as Camera3D
@onready var initial_rotation := camera.rotation_degrees as Vector3
# BlackScreen
@onready var black_screen := $CanvasLayer/BlackScreen

func _ready() -> void:
	original_position = position
	if not earthquake_enabled:
		return
	
#	Rotate camera 360
	var tween = create_tween()
	tween.tween_property(camera, "rotation_degrees:y", camera.rotation_degrees.y + 360, 5.0)
	await tween.finished
	
	game_state.player_can_move = true
	
#	Wait 5 seconds before earthquake starts
	await get_tree().create_timer(5.0).timeout
	_start_earthquake(earthquake_duration)

func _process(delta: float) -> void:
	time += delta
	
	if game_state.camera_under_table:
		global_position = global_position.lerp(game_state.camera_hide_pos, delta * 5.0)
	else:
		var angle_rad := deg_to_rad(-game_state.camera_angle)
		var offset_x := 0.017
		var offset_z := -0.29
		var radius := sqrt(offset_x * offset_x + offset_z * offset_z)
		var target_pos : Vector3 = Vector3(
			radius * sin(angle_rad),
			original_position.y,
			-radius * cos(angle_rad)
		)
		position = position.lerp(target_pos, delta * 5.0)
	
	if earthquake_active:
#		Refill trauma so it doesnt decay
		add_trauma(delta * 1.0)
	else:
	#	Max makes sure var trauma >= 0
		trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	
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
		
# Arrow keys to rotate camera
func _rotate_camera(degrees: float) -> void:
	game_state.camera_angle += degrees
	var angle_rad := deg_to_rad(game_state.camera_angle)
	
	var offset_x := 0.017
	var offset_z := -0.29
	var radius := sqrt(offset_x * offset_x + offset_z * offset_z)
	
	var new_x := radius * sin(-angle_rad)
	var new_z := -radius * cos(-angle_rad)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation_degrees:y", rotation_degrees.y + degrees, 0.3)
	tween.tween_property(self, "position:x", new_x, 0.3)
	tween.tween_property(self, "position:z", new_z, 0.3)
	await tween.finished
	initial_rotation = camera.rotation_degrees
