extends Node2D

signal floor_changed(int)

var body_check : TileMapLayer = null

func _on_floor_entered(body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body is TileMapLayer:
		_process_tile(body , body_rid)

func _process_tile(tile_map : TileMapLayer, body_rid : RID):
	var tile_position : Vector2 = tile_map.get_coords_for_body_rid(body_rid)
	var tile_data := tile_map.get_cell_tile_data(tile_position)
	var tile : int = tile_data.get_custom_data_by_layer_id(0)
	emit_signal("floor_changed", tile)
	
	
