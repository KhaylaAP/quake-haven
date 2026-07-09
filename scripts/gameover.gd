extends Control

func _on_retry_pressed() -> void:
	game_state.player_can_move = false
	get_tree().change_scene_to_file(game_state.LEVEL_PATHS[game_state.current_level])

func _on_exit_pressed() -> void:
	game_state.player_can_move = false
	get_tree().change_scene_to_file("res://scenes/levelselect.tscn")
