@tool
extends EditorPlugin

const MainView = preload("res://addons/tilemap_merger/main_view.tscn")

var main_view

func _enter_tree():
	main_view = MainView.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(main_view)
	_make_visible(false)
	
	InputMap.add_action("isometric_tilemap_editor_middle_click")
	var right_click = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_MIDDLE
	InputMap.action_add_event("isometric_tilemap_editor_middle_click", right_click)

func _exit_tree():
	if is_instance_valid(main_view):
		main_view.queue_free()
	InputMap.erase_action("isometric_tilemap_editor_middle_click")

func _has_main_screen():
	return true


func _make_visible(visible):
	if main_view:
		main_view.visible = visible

func _get_plugin_name():
	return "TilemapMerger"
