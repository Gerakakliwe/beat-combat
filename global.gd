extends Node
var ogg_path: String = ""
var ogv_path: String = ""
var json_path: String = ""
var zip_path: String = ""
var player_height: float = 185.0
var player_reach: int = 72
var level_metadata_cache: Dictionary = {}

var config_path := "user://settings.cfg"

func save_settings():
	print("save")
	var config = ConfigFile.new()
	config.set_value("player", "height", player_height)
	config.set_value("player", "reach", player_reach)
	config.save(config_path)

func load_settings():
	print("load")
	var config = ConfigFile.new()
	var err = config.load(config_path)
	if err == OK:
		player_height = config.get_value("player", "height", 185)
		player_reach = config.get_value("player", "reach", 65)
