extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Set up pause screen so I don't have to make another script :P
	$Pause.visible = false
	$Pause.process_mode = Node.PROCESS_MODE_ALWAYS
	$Pause/VBoxContainer/resume.connect("pressed", func unpause(): get_tree().paused = false)
	$Pause/VBoxContainer/quit.connect("pressed", get_tree().quit)
	pass
	
func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
	$Pause.visible = get_tree().paused
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _physics_process(_delta):
	# goes to 2 decimal places
	$BottomLeftHUD/Speedometer.text = str((round(Vector2($Player.velocity.x, $Player.velocity.z).length()))) + " m/s"
