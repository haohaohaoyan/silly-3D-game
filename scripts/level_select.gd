extends Control

@export var levelName : String = "Blank"
@export var levelFirstPath : String
@export var levelThumbnail : String
const game_main_scene_packed = preload("res://scenes/game.tscn")

func _ready():
	$MarginContainer/VBoxContainer/LevelThumbnail.texture = load(levelThumbnail)
	$MarginContainer/VBoxContainer/LevelTitle.text = levelName
	$StartButton.connect("pressed", change_level.bind(levelFirstPath))
	
func change_level(path):
	var game_scene = game_main_scene_packed.instantiate()
	get_tree().get_root().add_child(game_scene)
	game_scene.load_level(path)
	get_tree().get_root().get_node("TitleScreen").queue_free()
	
