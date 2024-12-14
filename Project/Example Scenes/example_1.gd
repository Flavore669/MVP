extends Node2D

#CONDITIONS FOR CRASH: Having a Enemy with PatrolPoints as children should be the trigger for the crashes,
#Having an enemy by itself or PatrolPoints without an Enemy child should not occur with a crash

const MENU = preload("res://Project/Example Scenes/menu.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(MENU)
