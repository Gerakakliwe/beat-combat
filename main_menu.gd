extends Node3D

var xr_interface: XRInterface
@onready var v_box_container: VBoxContainer = $Viewport2Din3D/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer
@onready var start_button: Button = $Viewport2Din3D/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/StartButton

var map_buttons = []
var selected_map_button = null

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	
	var zip_files = get_zip_files("res://projects")
	for zip_path in zip_files:
		add_map_button(zip_path)

func get_zip_files(path: String) -> Array:
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Failed to open directory: " + path)
		return []
	
	var zip_list = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".zip"):
			zip_list.append(path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	return zip_list

func add_map_button(zip_path: String):
	var map_list_container = v_box_container
	var button = Button.new()
	button.text = zip_path.get_file().replace(".zip", "").capitalize()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 100)
	button.connect("pressed", Callable(self, "_on_map_button_pressed").bind(zip_path, button))
	map_list_container.add_child(button)
	map_buttons.append(button)

func _on_map_button_pressed(zip_path: String, pressed_button: Button):
	print("Loading map from:", zip_path)
	Global.zip_path = zip_path
	start_button.disabled = false

	for btn in map_buttons:
		btn.remove_theme_color_override("font_color")
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_stylebox_override("pressed")

	pressed_button.add_theme_color_override("font_color", Color.WHITE)
	var highlight = StyleBoxFlat.new()
	highlight.bg_color = Color("0077ff")
	pressed_button.add_theme_stylebox_override("normal", highlight)
	pressed_button.add_theme_stylebox_override("hover", highlight)
	pressed_button.add_theme_stylebox_override("pressed", highlight)

	selected_map_button = pressed_button

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
