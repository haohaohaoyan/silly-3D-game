extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	$Player.connect("checkpoint_reached", show_checkpoint)
	$BottomLeftHUD/VBoxContainer/CheckpointAnnouncement.modulate.a = 0
	
func load_level(path):
	var new_level = load(path).instantiate()
	$current_level.add_child(new_level)
	$Player.global_transform = $current_level.get_child(0).get_node("SpawnPlayer").global_transform
	$Player.respawn_checkpoint = $current_level.get_child(0).get_node("SpawnPlayer").global_position
	
func _physics_process(_delta):
	# goes to 2 decimal places
	$BottomLeftHUD/VBoxContainer/Speedometer.text = str((round(Vector2($Player.velocity.x, $Player.velocity.z).length()))) + " m/s"
	
func show_checkpoint():
	$BottomLeftHUD/VBoxContainer/CheckpointAnnouncement.modulate.a = 1
	var fade_out = create_tween()
	fade_out.tween_property($BottomLeftHUD/VBoxContainer/CheckpointAnnouncement, "modulate:a", 0, 3)
	fade_out.tween_callback(fade_out.kill)
