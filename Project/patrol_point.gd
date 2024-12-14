extends Node2D
class_name PatrolPoints
#FIXME: THIS CAUSES CRASHES


@export var time_idle : float =  2.0
@export var match_rotation := false
var pos : Vector2
var rot : float

func _ready() -> void:
	pos = global_transform.origin
	rot = global_transform.get_rotation()

func return_pos() -> Vector2:
	return pos

func return_rotation() -> Vector2:
	return pos + Vector2.RIGHT.rotated(rot) * 90
	
	
