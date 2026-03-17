extends Control

func _ready():
	get_tree().paused = false
	$MarginContainer/Control/VBoxContainer/QuitButton.connect("pressed", get_tree().quit) # ok wtf
	$MarginContainer/Control/VBoxContainer/PlayButton.connect("pressed", func toggle_select() : $LevelSelect.visible = !$LevelSelect.visible)
	$LevelSelect/Button.connect("pressed", func toggle_select() : $LevelSelect.visible = !$LevelSelect.visible)
