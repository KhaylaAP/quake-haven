extends Button

var level_index := 0

func setup(index: int) -> void:
	level_index = index
	if index == 0:
		text = "Tutorial"
	else:
		text = str(index)
		
	if game_state.is_level_unlocked(index):
		modulate.a = 1.0
		disabled = false
	else:
		modulate.a = 0.5
		disabled = true
	
	_update_scores()

func _on_pressed() -> void:
	if game_state.is_level_unlocked(level_index):
		game_state.current_level = level_index
		game_state.has_player_pos = false
		get_tree().call_deferred("change_scene_to_file", game_state.load_level(level_index))
		
func _update_scores() -> void:
	var last_label := get_node_or_null("Scores/LastScore")
	var best_label := get_node_or_null("Scores/BestScore")
	
	if last_label: 
		if level_index in game_state.last_scores:
			last_label.text = "Latest: " + str(game_state.last_scores[level_index])
		else:
			last_label.text = "Latest: - "
	
	if best_label: 
		if level_index in game_state.best_scores:
			best_label.text = "Best: " + str(game_state.best_scores[level_index])
		else:
			best_label.text = "Best: - "
