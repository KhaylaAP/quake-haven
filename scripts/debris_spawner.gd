extends Node3D

@export var debris_scene: PackedScene

# Spawn area
@export var room_min := Vector3(-8.0, 0, -8.0)
@export var room_max := Vector3(8.0, 0, 8.0)
@export var spawn_height := 8.0

@export var spawn_interval := 0.5

@export var debris_min := 0
@export var debris_max := 50

var total_debris := 0
var spawned := 0
var is_active := false

func _ready() -> void:
	game_state.earthquake_start.connect(start)
	game_state.earthquake_end.connect(stop)
	
func start() -> void:
	is_active = true
	total_debris = randi_range(debris_min, debris_max)
	spawned = 0
	
	var timer = Timer.new()
	add_child(timer)
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	timer.wait_time = spawn_interval
	timer.timeout.connect(_spawn_one.bind(timer))
	timer.start()
	
func _spawn_one(timer: Timer) -> void:
	if not is_active or spawned >= total_debris:
		timer.queue_free()
		return
	
	var debris = debris_scene.instantiate()
	get_tree().current_scene.add_child(debris)
	
#	Temp to spawn at one point to debug
	#debris.global_position = Vector3(-2.5, spawn_height, -0.5)
	
	debris.global_position = Vector3(
		randf_range(room_min.x, room_max.x),
		spawn_height,
		randf_range(room_min.z, room_max.z),	
	)
	
	spawned += 1
	
func stop() -> void:
	is_active = false
