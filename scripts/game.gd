extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass
	
func _physics_process(_delta):
	# goes to 2 decimal places
	$BottomLeftHUD/Speedometer.text = str(round(Vector2($Player.velocity.x, $Player.velocity.y).length()*10)/10) + " m/s"
