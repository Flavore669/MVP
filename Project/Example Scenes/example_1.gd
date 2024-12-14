extends Node2D


const MENU = preload("res://Project/Example Scenes/menu.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(MENU)
