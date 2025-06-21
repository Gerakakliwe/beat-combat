extends Node3D

@onready var hit_counter: Label3D = $HitCounter
@onready var velocity_display: Label3D = $VelocityDisplay
@onready var miss_zone: Area3D = $MissZone
@onready var player: XROrigin3D = $Player
@onready var pause_ui: Node3D = $PauseUI
@onready var audio_stream_player: AudioStreamPlayer = $MusicSpawner/AudioStreamPlayer
@onready var video_stream_player: VideoStreamPlayer = $VideoPlayer/Viewport/Video/VideoStreamPlayer

var xr_interface: XRInterface
var points: int = 0
var combo: int = 0

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		audio_stream_player.playing = false
		Global.ogv_path = ""
		get_tree().paused = false
		get_tree().change_scene_to_file("res://levels/main_menu/main_menu.tscn")

func _ready() -> void:
	var video_stream = VideoStreamTheora.new()
	video_stream.file = Global.ogv_path
	video_stream_player.stream = video_stream
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true

	player.global_position = Vector3(0, 0, Global.player_reach * 0.01)

func _on_player_target_hit(points_awarded: int) -> void:
	points += points_awarded
	combo += 1
	update_results()

func _on_player_obstacle_hit() -> void:
	combo = 0
	update_results()

func _on_player_wrong_target_hit() -> void:
	combo = 0
	update_results()

func _on_player_hit_velocity(velocity_vector: Variant) -> void:
	velocity_display.text = str("X: " + str(snapped(velocity_vector.x, 0.1)) + "\n" +
								"Y: " + str(snapped(velocity_vector.y, 0.1)) + "\n" +
								"Z: " + str(snapped(velocity_vector.z, 0.1)))


func _on_miss_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group("knee_target") or body.is_in_group("knee_hit_zone"):
		if player and player.has_method("cancel_knee_strike"):
			player.cancel_knee_strike()
			combo = 0
			update_results()
	if body.is_in_group("left_target") or body.is_in_group("right_target"):
		combo = 0
		update_results()
	if body.is_in_group("obstacle") and combo > 2:
		combo += 1
		points += 500
		update_results()
	body.free()

func update_results():
	hit_counter.text = "Combo: " + str(combo) + "\nPoints: " + str(points)

func _on_controller_left_button_pressed(name: String) -> void:
	if name == "menu_button":
		var paused = not get_tree().paused
		get_tree().paused = paused
		pause_ui.visible = paused

		if paused:
			pause_ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		else:
			pause_ui.process_mode = Node.PROCESS_MODE_DISABLED

func _on_main_menu_pressed() -> void:
	audio_stream_player.playing = false
	Global.ogv_path = ""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://levels/main_menu/main_menu.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	pause_ui.visible = false
	pause_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().change_scene_to_file("res://levels/main/main.tscn")

func _on_continue_pressed() -> void:
	get_tree().paused = false
	pause_ui.visible = false
	pause_ui.process_mode = Node.PROCESS_MODE_DISABLED

func _on_music_spawner_start_video() -> void:
	video_stream_player.play()
