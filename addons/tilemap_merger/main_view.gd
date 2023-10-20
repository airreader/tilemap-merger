@tool
extends Control


const MAIN_TILEMAP_PATH = "res://addons/tilemap_merger/main_tile_map.tscn"


# vars
var selected_tile_set: TileSet:
	set(new_tile_set):
		main_tilemap.tile_set = new_tile_set
		temp_tilemap.tile_set = new_tile_set
		%TileMaps.tile_size = new_tile_set.tile_size
		%TileMaps.queue_redraw()
		var array = new_tile_set.resource_path.split("/", true, 0)
		tile_set_menu_button.text = array[array.size()-1]
		selected_tile_set = new_tile_set
	get:
		return selected_tile_set

var selected_tile_map: TileMap:
	set(new_tile_map):
		var file_path = new_tile_map.scene_file_path
		var array = file_path.split("/", true, 0)
		%SelectTileMapButton.text = array[array.size()-1]
		selected_tile_map_data = load_tile_map(new_tile_map)
		selected_tile_map = new_tile_map
	get:
		return selected_tile_map
		
var selected_tile_map_data: Dictionary
var temp_tile_map_data: Dictionary

var selected_trap_rotate_degree: int = 0:
	set(new_degree):
		selected_trap_rotate_degree = new_degree
		selected_tile_map_data = load_tile_map(selected_tile_map, new_degree)
	get:
		return selected_trap_rotate_degree
		
var pointed_tile_position: Vector2i = Vector2i(0,0)

var unified_tile_size: int = 7
var mouse_hovered_tilemap_container = false

# tilemaps
@onready var main_tilemap := %TileMap as TileMap
@onready var temp_tilemap := %TempTileMap as TileMap

# Dialogs
@onready var tile_set_dialog: FileDialog = %TileSetDialog as FileDialog
@onready var tile_map_folder_dialog: FileDialog = %TileMapFolderDialog as FileDialog
@onready var save_as_tile_map_dialog: FileDialog = %SaveAsTileMapDialog as FileDialog
@onready var open_main_tile_map_dialog := %OpenMainTileMapDialog as FileDialog

# MenuButton
@onready var tile_set_menu_button: MenuButton = %TileSetMenuButton as MenuButton
@onready var tile_map_folder_menu_button: MenuButton = %TileMapFolderMenuButton as MenuButton

# etc
@onready var tile_map_grid_container: GridContainer = %TileMapGridContainer as GridContainer
@onready var files = %Files as VBoxContainer

func _ready():
	%TileMapFolderMenuButton.icon = get_theme_icon("Load", "EditorIcons")
	%SelectTileMapButton.icon = get_theme_icon("Load", "EditorIcons")
	%TileSetMenuButton.icon = get_theme_icon("GuiDropdown", "EditorIcons")


func _input(event):
	if mouse_hovered_tilemap_container && selected_tile_set && selected_tile_map:
		if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
			set_tile_map(temp_tile_map_data)
		if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_RIGHT:
			erase_unified_tile_map(temp_tile_map_data)
		if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_WHEEL_UP:
			rotate_degree()
			update_temp_tilemap()
		if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			rotate_degree(true)
			update_temp_tilemap()
	if mouse_hovered_tilemap_container:
		if event is InputEventMouseButton && event.pressed && event.button_index == 6: #button_index == 6 は shift+WHEEL_UP
			(%TileMaps as Node2D).scale += Vector2(0.05, 0.05)
		if event is InputEventMouseButton && event.pressed && event.button_index == 7: #button_index == 7 は shift+WHEEL_DOWN
			(%TileMaps as Node2D).scale -= Vector2(0.05, 0.05)


func _process(_delta):
	if selected_tile_set == null || selected_tile_map == null:
		return
	var current_pointed_tile_position = main_tilemap.local_to_map(main_tilemap.get_local_mouse_position())
	if current_pointed_tile_position == pointed_tile_position:
		return
	pointed_tile_position = current_pointed_tile_position
	update_temp_tilemap()
	

func update_temp_tilemap(tile_data: Dictionary = selected_tile_map_data, tile_position: Vector2i = Vector2i(snappedi(pointed_tile_position.x, unified_tile_size), snappedi(pointed_tile_position.y, unified_tile_size))):
	temp_tilemap.clear()
	temp_tile_map_data = {
		"tile_set_path": tile_data.tile_set_path,
		"tile_data": []
	}
	for data in tile_data.tile_data:
		temp_tilemap.set_cell(data.layer, data.cell_position + tile_position, data.source_id, data.atlas_coords, data.alternative_id)
		temp_tile_map_data.tile_data.append({
			"layer": data.layer,
			"cell_position": data.cell_position + tile_position,
			"source_id": data.source_id,
			"atlas_coords": data.atlas_coords,
			"alternative_id": data.alternative_id,
		})
	
	
func set_tile_map(tile_data: Dictionary):
	for data in tile_data.tile_data:
		main_tilemap.set_cell(data.layer, data.cell_position, data.source_id, data.atlas_coords, data.alternative_id)
	files.edit_file(load_tile_map(main_tilemap))


func erase_unified_tile_map(tile_data: Dictionary):
	temp_tilemap.clear()
	for data in tile_data.tile_data:
		main_tilemap.erase_cell(data.layer, data.cell_position)
	

func build_tile_set_menu() -> void:
	var menu := tile_set_menu_button.get_popup()
	menu.clear()
	menu.add_item("Load", 1)
	menu.add_item("Clear", 2)

	if menu.id_pressed.is_connected(_on_open_menu_id_pressed):
		menu.id_pressed.disconnect(_on_open_menu_id_pressed)
	menu.id_pressed.connect(_on_open_menu_id_pressed)




func rotate_degree(is_left: bool = false):
	if is_left:
		selected_trap_rotate_degree -= 90
		if selected_trap_rotate_degree == -90:
			selected_trap_rotate_degree = 270
	else:
		selected_trap_rotate_degree += 90
		if selected_trap_rotate_degree == 360:
			selected_trap_rotate_degree = 0


func load_tile_map(tilemap: TileMap, degree: int = 0) -> Dictionary:
	var layer_count = tilemap.get_layers_count()
	var tile_set_path = ""
	if selected_tile_set != null:
		tile_set_path = selected_tile_set.resource_path
	var tile_data: Dictionary = {
		"tile_set_path": tile_set_path,
		"tile_data": []
	}
	for i in range(0, layer_count):
		var cells_position = tilemap.get_used_cells(i)
		for v in cells_position:
			# 回転させたい
			var cell_position = Vector2i(0,0)
			var rad = deg_to_rad(degree)
			cell_position.x = round(v.x * cos(rad) - v.y * sin(rad))
			cell_position.y = round(v.x * sin(rad) + v.y * cos(rad))
			var ajustment = Vector2i(0,0)
			if degree == 90:
				ajustment = Vector2i(-2*i, 0)
			if degree == 180:
				ajustment = Vector2i(-2*i, -2*i)
			if degree == 270:
				ajustment = Vector2i(0, -2*i)
			cell_position += ajustment
			# 回転ここまで

			
			var new_cell_source_id = tilemap.get_cell_source_id(i, v)
			var new_cell_atlas_coords: Vector2i = tilemap.get_cell_atlas_coords(i, v)
			var new_cell_alternative_id: int = tilemap.get_cell_alternative_tile(i,v)
			#if new_cell_source_id == four_set_tileset_source_id: # stairsの場合
				#var x = new_cell_atlas_coords.x
				#x += selected_trap_rotate_degree / 90
				#x = int(x)
				#new_cell_atlas_coords.x = x % 4
			tile_data.tile_data.append({
				"layer": i,
				"cell_position": cell_position,
				"source_id": new_cell_source_id,
				"atlas_coords": new_cell_atlas_coords,
				"alternative_id": new_cell_alternative_id,
			})
	return tile_data
	
	

	
func get_current_file_paths(dir_path: String) -> Array[String]:
	var dir = DirAccess.open(dir_path)
	var file_names: Array[String] = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				file_names.append(dir_path + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return file_names
	
	
func filter_tilemap_file(file_paths: Array[String]) -> Array[TileMap]:
	var tilemaps:Array[TileMap] = []
	for path in file_paths:
		if path.ends_with(".tscn"):
			var scene = load(path).instantiate()
			if  scene is TileMap:
				tilemaps.append(scene)
			else:
				scene.queue_free()
	return tilemaps
	
	
func build_grid_container(tilemaps: Array[TileMap]):
	if tile_map_grid_container.get_child_count() > 0 && tile_map_grid_container.get_child(0):
		for child in tile_map_grid_container.get_children():
			child.queue_free()
	for tilemap in tilemaps:
		var button = Button.new()
		button.custom_minimum_size.x = 160
		button.custom_minimum_size.y = 150
		button.add_child(trap_image(tilemap, 160))
		button.pressed.connect(func():
			selected_tile_map = tilemap
		)
		tile_map_grid_container.add_child(button)

	
	
func load_to_main_tile_map(tile_data: Dictionary):
	main_tilemap.clear()
	for data in tile_data.tile_data:
		main_tilemap.set_cell(data.layer, data.cell_position, data.source_id, data.atlas_coords, data.alternative_id)

func _on_tile_map_dialog_file_selected(path: String):
	var tilemap = (load(path) as PackedScene).instantiate()
	if tilemap is TileMap:
		selected_tile_map = tilemap
	
	
static func trap_image(tilemap: TileMap, width: float) -> MarginContainer:
	var image_container := MarginContainer.new()
	var rect:Rect2i = tilemap.get_used_rect()
	
	var top_left_position := Vector2i(rect.position.x, rect.position.y)
	var top_right_position := Vector2i(rect.position.x + rect.size.x, rect.position.y)
	var bottom_left_position := Vector2i(rect.position.x, rect.position.y - rect.size.y)
	var bottom_right_position := Vector2i(rect.position.x + rect.size.x, rect.position.y - rect.size.y)

	var top_left := tilemap.map_to_local(top_left_position)
	var top_right := tilemap.map_to_local(top_right_position)
	var bottom_left = tilemap.map_to_local(bottom_left_position)
	var bottom_right = tilemap.map_to_local(bottom_right_position)
	
	var image_size_x = bottom_right.x - top_left.x
	var image_size_y = top_right.y - bottom_left.y + 128
	
	var center = tilemap.map_to_local(rect.position + rect.size / 2)
	var scale = width / image_size_x
	var size_y = image_size_y * scale

	image_container.size.x = width
	image_container.size.y = size_y
	image_container.clip_contents = true
	
	tilemap.scale = Vector2(scale, scale)
	tilemap.position = Vector2((width/2) - center.x * scale, size_y / 2 - center.y * scale + 8)
	
	image_container.add_child(tilemap)
	return image_container


func _on_select_tile_map_button_pressed():
	%TileMapDialog.popup_centered()



func _on_open_menu_id_pressed(id: int) -> void:
	match id:
		1:
			tile_set_dialog.popup_centered()
		2:
			selected_tile_set = null
			

func _on_tile_set_menu_button_about_to_popup():
	build_tile_set_menu()


func _on_tile_set_dialog_file_selected(path: String):
	selected_tile_set = load(path) as TileSet
	

func _on_tile_map_folder_menu_button_pressed():
	tile_map_folder_dialog.popup_centered()


func _on_save_as_button_pressed():
	save_as_tile_map_dialog.popup_centered()
	
func _on_save_button_pressed():
	files.save_as_file(load_tile_map(main_tilemap))


func _on_open_button_pressed():
	open_main_tile_map_dialog.popup_centered()


func _on_tile_map_folder_dialog_dir_selected(dir_path: String):
	%TileMapFolderMenuButton.text = dir_path
	var paths = get_current_file_paths(dir_path)
	var tilemaps = filter_tilemap_file(paths)
	build_grid_container(tilemaps)


func _on_open_main_tile_map_dialog_file_selected(path):
	var tilemap = (load(path) as PackedScene).instantiate()
	if not tilemap is TileMap:
		return
	if tilemap.tile_set != null:
		selected_tile_set = tilemap.tile_set
	var tile_data = load_tile_map(tilemap)
	load_to_main_tile_map(tile_data)
	files.open_file(path, tile_data)


func _on_save_as_tile_map_dialog_file_selected(path):
	files.save_as_file(load_tile_map(main_tilemap), path)


func _on_files_file_selected(tile_data):
	load_to_main_tile_map(tile_data)
	%SaveButton.disabled = false
	

func _on_tile_size_spin_box_value_changed(value):
	unified_tile_size = value


func _on_tile_map_container_mouse_entered():
	mouse_hovered_tilemap_container = true


func _on_tile_map_container_mouse_exited():
	mouse_hovered_tilemap_container = false
