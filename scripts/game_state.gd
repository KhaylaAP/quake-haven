extends Node

var player_can_move := false
var earthquake_active := false
var last_player_pos := Vector3.ZERO
var has_player_pos := false
var last_player_health := 100

signal earthquake_start
signal earthquake_end
