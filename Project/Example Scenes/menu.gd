extends Control


func _on_example_1_pressed() -> void:
	get_tree().change_scene_to_packed(ResourceLoader.load("res://Project/Example Scenes/example_1.tscn"))


func _on_example_2_pressed() -> void:
	get_tree().change_scene_to_packed(ResourceLoader.load("res://Project/Example Scenes/example_2.tscn"))
	
