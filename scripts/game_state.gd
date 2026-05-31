extends Node

signal earthquake_start
signal earthquake_end

# Unlock all levels to debug and test
var unlock_all := false

var player_can_move := false
var earthquake_active := false

var last_player_pos := Vector3.ZERO
var has_player_pos := false
var last_player_health := 100

var current_level := 0
var levels_unlocked := 1

var last_scores := {}
var best_scores := {}

var camera_angle := 0.0
var camera_under_table := false
var camera_hide_pos := Vector3.ZERO

var was_hiding := false
var was_hiding_sofa := false
var was_hiding_wall := false
var hide_spot_pos := Vector3.ZERO
var hiding_damage_applied := false


const LEVEL_PATHS = {
	0: "res://scenes/tutorial.tscn",
	1: "res://scenes/levels/1.tscn",
	2: "res://scenes/levels/2.tscn",
	3: "res://scenes/levels/3.tscn",
	4: "res://scenes/levels/4.tscn",
	5: "res://scenes/levels/5.tscn",
}

const BROKEN_PATHS = {
	1: "res://scenes/broken_levels/brkn_1.tscn",
	2: "res://scenes/broken_levels/brkn_2.tscn",
	3: "res://scenes/broken_levels/brkn_3.tscn",
	4: "res://scenes/broken_levels/brkn_4.tscn",
	5: "res://scenes/broken_levels/brkn_5.tscn",
}

func _ready() -> void:
#	Unlock all levels
	if unlock_all:
		levels_unlocked = LEVEL_PATHS.size()
		
func load_level(index: int) -> String:
	if index in LEVEL_PATHS:
		return LEVEL_PATHS[index]
	return ""
	
func unlock_next_level() -> void:
	var next = current_level + 1
	if next < LEVEL_PATHS.size() and next >= levels_unlocked:
		levels_unlocked = next + 1
		
func is_level_unlocked(index: int) -> bool:
	if unlock_all:
		return true
	return index < levels_unlocked

func load_broken() -> String:
	if current_level in BROKEN_PATHS:
		return BROKEN_PATHS[current_level]
	return "res://scenes/broken.tscn"

func calculate_score() -> int:
	var score = int((last_player_health / 100.0) * 1000)
	return score
	
func save_score() -> void:
	var score = calculate_score()
	last_scores[current_level] = score
	if not current_level in best_scores or score > best_scores[current_level]:
		best_scores[current_level] = score
