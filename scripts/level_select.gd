extends Control

@onready var grid := $CenterContainer/GridContainer

func _ready() -> void:
	for i in grid.get_child_count():
		var btn = grid.get_child(i)
		if btn.has_method("setup"):
			btn.setup(i)

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
