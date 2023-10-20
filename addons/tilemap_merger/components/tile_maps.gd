@tool
extends Node2D

var tile_size:Vector2 = Vector2(32,-16)

var dragging = false
var drag_start_position: Vector2

func _draw():
	draw_line(Vector2(0, tile_size.y/2), Vector2(tile_size.x/2, tile_size.y), Color.RED, 1.0)
	draw_line(Vector2(tile_size.x/2, tile_size.y), Vector2(tile_size.x, tile_size.y/2), Color.RED, 1.0)
	draw_line(Vector2(tile_size.x, tile_size.y/2), Vector2(tile_size.x/2, 0), Color.RED, 1.0)
	draw_line(Vector2(tile_size.x/2, 0), Vector2(0, tile_size.y/2), Color.RED, 1.0)



func _process(_delta):
	if Input.is_action_just_pressed("isometric_tilemap_editor_middle_click"):
		dragging = true
		drag_start_position = get_viewport().get_mouse_position()
	if Input.is_action_pressed("isometric_tilemap_editor_middle_click"):
		position = position - (drag_start_position - get_viewport().get_mouse_position())
		drag_start_position = get_viewport().get_mouse_position()
	if Input.is_action_just_released("isometric_tilemap_editor_middle_click"):
		dragging = false
