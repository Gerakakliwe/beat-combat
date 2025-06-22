extends Node3D

@onready var start_button: Button = $Start/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/StartButton
@onready var scroll_container: ScrollContainer = $Levels/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/ScrollContainer
@onready var levels_container: VBoxContainer = $Levels/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/ScrollContainer/LevelsContainer
@onready var basic_tab: Button = $Levels/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/BasicTab
@onready var custom_tab: Button = $Levels/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/CustomTab
@onready var loading_label: Label3D = $LoadingLabel
@onready var levels: Node3D = $Levels
@onready var start: Node3D = $Start
@onready var settings: Node3D = $Settings

@onready var height_slider: HSlider = $Settings/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/HeightContainer/HeightSlider
@onready var current_height: Label = $Settings/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/HeightContainer/CurrentHeight

@onready var reach_slider: HSlider = $Settings/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/ReachContainer/ReachSlider
@onready var current_reach: Label = $Settings/Viewport/CanvasLayer/Control/ColorRect/MarginContainer/VBoxContainer/ReachContainer/CurrentReach

var xr_interface: XRInterface
var map_buttons = []
var selected_map_button = null
var is_loading = false
var loading_started = false
var map_select_value = -1

func _input(event):
	if event.is_action_pressed("ui_page_up"):
		map_select_value -= 1
		if map_select_value < 0:
			map_select_value = 0
		map_buttons[map_select_value].emit_signal("pressed")

	if event.is_action_pressed("ui_page_down"):
		map_select_value += 1
		if map_select_value > map_buttons.size() - 1:
			map_select_value = map_buttons.size() - 1
		map_buttons[map_select_value].emit_signal("pressed")

	if event.is_action_pressed("ui_down"):
		scroll_container.scroll_vertical += 50

	if event.is_action_pressed("ui_up"):
		scroll_container.scroll_vertical -= 50

	if event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()

func _ready() -> void:
	Global.load_settings()
	OS.request_permissions()
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true

	basic_tab.add_theme_color_override("font_color", Color.WHITE)
	var highlight = StyleBoxFlat.new()
	highlight.bg_color = Color("0077ff")
	basic_tab.add_theme_stylebox_override("normal", highlight)
	basic_tab.add_theme_stylebox_override("hover", highlight)
	basic_tab.add_theme_stylebox_override("pressed", highlight)

	var zip_files = get_zip_files("res://projects")
	for zip_path in zip_files:
		add_map_button(zip_path)

	height_slider.value = Global.player_height
	reach_slider.value = Global.player_reach

func _process(_delta: float) -> void:
	if is_loading and not loading_started:
		ResourceLoader.load_threaded_request("res://levels/main/main.tscn")
		loading_started = true
	elif is_loading:
		var status = ResourceLoader.load_threaded_get_status("res://levels/main/main.tscn")
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var new_scene = ResourceLoader.load_threaded_get("res://levels/main/main.tscn")
			get_tree().change_scene_to_packed(new_scene)

	var cm = height_slider.value
	var total_inches = cm / 2.54
	var feet = int(total_inches / 12)
	var inches = int(round(fmod(total_inches, 12)))

	current_height.text = str(int(cm)) + " cm (" + str(feet) + "'" + str(inches) + "\")"

	current_reach.text = str(int(reach_slider.value))

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
	var map_list_container = levels_container
	var button = Button.new()
	button.text = zip_path.get_file().replace(".zip", "").capitalize()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 100)
	button.focus_mode = Control.FOCUS_NONE
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
	is_loading = true
	loading_started = false
	levels.visible = false
	start.visible = false
	settings.visible = false
	$LoadingLabel.visible = true

func _on_controller_left_input_vector_2_changed(name: String, value: Vector2) -> void:
	var threshold = 0.1
	if value.y > threshold: # up
		scroll_container.scroll_vertical -= 20
	elif value.y < -threshold: # down
		scroll_container.scroll_vertical += 20

func _on_controller_right_input_vector_2_changed(name: String, value: Vector2) -> void:
	var threshold = 0.1
	if value.y > threshold: # up
		scroll_container.scroll_vertical -= 20
	elif value.y < -threshold: # down
		scroll_container.scroll_vertical += 20

func _on_basic_tab_pressed() -> void:
	map_buttons.clear()
	for child in levels_container.get_children():
		levels_container.remove_child(child)
		child.queue_free()

	custom_tab.remove_theme_color_override("font_color")
	custom_tab.remove_theme_stylebox_override("normal")
	custom_tab.remove_theme_stylebox_override("hover")
	custom_tab.remove_theme_stylebox_override("pressed")

	basic_tab.add_theme_color_override("font_color", Color.WHITE)
	var highlight = StyleBoxFlat.new()
	highlight.bg_color = Color("0077ff")
	basic_tab.add_theme_stylebox_override("normal", highlight)
	basic_tab.add_theme_stylebox_override("hover", highlight)
	basic_tab.add_theme_stylebox_override("pressed", highlight)

	var zip_files = get_zip_files("res://projects")
	for zip_path in zip_files:
		add_map_button(zip_path)

func _on_custom_tab_pressed() -> void:
	map_buttons.clear()
	for child in levels_container.get_children():
		levels_container.remove_child(child)
		child.queue_free()

	basic_tab.remove_theme_color_override("font_color")
	basic_tab.remove_theme_stylebox_override("normal")
	basic_tab.remove_theme_stylebox_override("hover")
	basic_tab.remove_theme_stylebox_override("pressed")

	custom_tab.add_theme_color_override("font_color", Color.WHITE)
	var highlight = StyleBoxFlat.new()
	highlight.bg_color = Color("0077ff")
	custom_tab.add_theme_stylebox_override("normal", highlight)
	custom_tab.add_theme_stylebox_override("hover", highlight)
	custom_tab.add_theme_stylebox_override("pressed", highlight)

	var zip_files = get_zip_files("/sdcard/CustomMaps/")
	if zip_files.is_empty():
		var label = Label.new()
		label.text = "No custom levels were found.\nPlace your .zip archives into:\n/sdcard/CustomMaps/"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 50)
		levels_container.add_child(label)
	else:
		for zip_path in zip_files:
			add_map_button(zip_path)

func _on_reach_slider_value_changed(value: float) -> void:
	Global.player_reach = int(reach_slider.value)
	Global.save_settings()

func _on_height_slider_value_changed(value: float) -> void:
	Global.player_height = int(height_slider.value)
	Global.save_settings()
