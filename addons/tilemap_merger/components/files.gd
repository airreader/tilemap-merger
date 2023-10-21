@tool
extends VBoxContainer

signal file_selected(tile_data: Array[Dictionary])
signal file_deselected()
signal file_reload_button_pressed(file_path: String)

const MAIN_TILEMAP_PATH = "res://addons/tilemap_merger/main_tile_map.tscn"
const MODIFIED_SUFFIX = "(*)"
const FILE_LIST_MENU_LIST_CLOSE = 1
const FILE_LIST_MENU_LIST_RELOAD = 2


var files: Dictionary = {}
#{
	#"file_path": {
		#"unsaved": bool,
		#"buffer_tile_data": Array[Dictionary]
	#}
#}
var current_file_path: String = ""

var editor_plugin: EditorPlugin

@onready var filter_edit: LineEdit = $FileFilter
@onready var list: ItemList = $FileList
@onready var popup_menu: PopupMenu = %FileListPopupMenu

		
func save_as_file(tile_data: Dictionary, file_path: String = current_file_path):
	if files.has(file_path):
		files[file_path].unsaved = false
		files[file_path].buffer_tile_data = tile_data
		update_file_list()
		store_tile_map(file_path, tile_data)
		editor_plugin.get_editor_interface().get_resource_filesystem().reimport_files([file_path])
		editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	else:
		add_list_new_file(file_path, tile_data)
		store_tile_map(file_path, tile_data)
		editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	
		
func edit_file(tile_data: Dictionary):
	if current_file_path != "":
		files[current_file_path].unsaved = true
		files[current_file_path].buffer_tile_data = tile_data
	update_file_list()
	
	
func open_file(file_path: String, tile_data: Dictionary):
	if files.has(file_path):
		files[file_path].buffer_tile_data = tile_data
		files[file_path].unsaved = false
		select_file(current_file_path)
	else:
		add_list_new_file(file_path, tile_data)
		select_file(file_path)


func reload_file(file_path: String, tile_data: Dictionary):
	if files.has(file_path):
		files[file_path].buffer_tile_data = tile_data
		files[file_path].unsaved = false
		update_file_list()

func add_list_new_file(file_path: String, tile_data: Dictionary):
	files[file_path] = {}
	files[file_path].unsaved = false
	files[file_path].buffer_tile_data = tile_data
	update_file_list()
	
	
	
func update_file_list() -> void:
	list.clear()
	var file_path_dict = file_path_dict()
	for file_path in files:
		var index: int
		var file_name = get_unique_file_name(file_path_dict, file_path)
		if files[file_path].unsaved:
			index = list.add_item(file_name +""+ MODIFIED_SUFFIX)
			list.set_item_metadata(index, { "file_path": file_path })
		else:
			index = list.add_item(file_name)
			list.set_item_metadata(index, { "file_path": file_path })
	select_file(current_file_path)
	
	
func get_unique_file_name(file_path_dict: Dictionary, file_path: String) -> String:
	var file_name = ""
	file_path = file_path.replace("res://", "")
	var dir_names = file_path.split("/")
	dir_names.reverse()
	var current = file_path_dict
	for dir_name in dir_names:
		if file_name == "":
			file_name = dir_name
		else:
			file_name = dir_name +"/"+file_name
		if current[dir_name].size() == 1:
			break;
		current = current[dir_name]
	return file_name

func file_path_dict() -> Dictionary:
	var result = {} 
	for file_path in files:
		file_path = file_path.replace("res://", "")
		var dir_names = file_path.split("/")
		dir_names.reverse()

		var current = result
		for dir_name in dir_names:
			if not current.has(dir_name):
				current[dir_name] = {}
			current = current[dir_name]
	return result

func select_file(file_path: String) -> void:
	if !file_path:
		return
	list.deselect_all()
	for i in range(0, list.get_item_count()):
		if file_path == list.get_item_metadata(i).file_path:
			list.select(i)
			current_file_path = file_path
			file_selected.emit(files[file_path].buffer_tile_data)


func _on_file_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var item_file_path = list.get_item_metadata(index).file_path
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		select_file(item_file_path)
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		build_popup_menu(item_file_path)
		popup_menu.position = get_local_mouse_position()
		popup_menu.popup()
		
		
func build_popup_menu(file_path: String):
	popup_menu.clear()
	popup_menu.add_item("close", FILE_LIST_MENU_LIST_CLOSE)
	popup_menu.set_item_metadata(popup_menu.get_item_index(FILE_LIST_MENU_LIST_CLOSE), file_path)
	popup_menu.add_separator()
	popup_menu.add_item("reload", FILE_LIST_MENU_LIST_RELOAD)
	popup_menu.set_item_metadata(popup_menu.get_item_index(FILE_LIST_MENU_LIST_RELOAD), file_path)
	

func store_tile_map(path: String, tile_data: Dictionary):
	var tile_map := TileMap.new() as TileMap
	tile_map.clear()
	tile_map.tile_set = load(tile_data.tile_set_path)
	for data in tile_data.tile_data:
		tile_map.set_cell(data.layer, data.cell_position, data.source_id, data.atlas_coords, data.alternative_id)
	var packed = PackedScene.new()
	packed.pack(tile_map)
	ResourceSaver.save(packed, path)


func _on_file_list_popup_menu_id_pressed(id: int):
	var file_path = popup_menu.get_item_metadata(popup_menu.get_item_index(id))
	match id:
		FILE_LIST_MENU_LIST_CLOSE:
			files.erase(file_path)
			if current_file_path == file_path:
				current_file_path = ""
				file_deselected.emit()
			update_file_list()
		FILE_LIST_MENU_LIST_RELOAD:
			file_reload_button_pressed.emit(file_path)
