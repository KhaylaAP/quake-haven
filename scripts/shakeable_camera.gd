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

@export var earthquake_duration := 15
@export var debris_min := 0
@export var debris_max := 50

#Shake intensity
var trauma := 0.0

var time := 0.0

var earthquake_active := false

@onready var camera := $Camera3D as Camera3D
@onready var initial_rotation := camera.rotation_degrees as Vector3
# BlackScreen
@onready var black_screen := $CanvasLayer/BlackScreen

func _ready() -> void:
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
