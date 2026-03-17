extends Control

const title_screen_path = "res://scenes/title_screen.tscn"
@onready var options_menu = $OptionsMenu/MarginContainer/ScrollContainer/VBoxContainer

func _ready():
	# set all button functions
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	$VBoxContainer/resume.connect("pressed", func unpause(): 
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	$VBoxContainer/retry.connect("pressed", owner.get_node("Player").death)
	$VBoxContainer/options.connect("pressed", toggle_options_popup)
	$VBoxContainer/quit.connect("pressed", func quit(): 
		get_tree().get_root().add_child(load(title_screen_path).instantiate())
		get_tree().get_root().get_node("Game").queue_free() # mmmmmm really awkward custom swapping
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)
	for kiddo in options_menu.get_children():
		kiddo.custom_minimum_size.x = $OptionsMenu/MarginContainer/ScrollContainer.size.x
	options_menu.get_node("SFXVolSlider").value = Options.sfx_volume
	options_menu.get_node("SFXVolSlider").connect("value_changed", func change_sfx_vol(value): Options.sfx_volume = value)
	$OptionsMenu/MarginContainer/OptionsBackButton.connect("pressed", toggle_options_popup)
	
func _process(_delta):
	visible = get_tree().paused
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
		$OptionsMenu.visible = false
		if get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
		
func toggle_options_popup(): 
	$OptionsMenu.visible = !$OptionsMenu.visible
