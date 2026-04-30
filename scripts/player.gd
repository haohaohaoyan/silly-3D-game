extends CharacterBody3D

# powers of 2 rahhhhhh
const SPEED = 8
const GRAVITY_MAX = -32
const GRAVITY_SPEED = 0.5
const SENSITIVITY = 0.00007 # what in the name of
const AIR_ACCEL = 0.5
const AIR_FRICTION = 0.1

var state : String
var last_state : String
var slide_vector : Vector3
var air_movement_vector: Vector3 # horizontal only, but y included for compatibility
var grapple_vector: Vector3

var respawn_checkpoint : Vector3 = Vector3(0,0,0)
signal checkpoint_reached

@onready var grapple = owner.get_node("Grapple")
@onready var line = owner.get_node("Line")

func _physics_process(_delta):
	var direction_input = Vector3(Input.get_axis("STRAFELEFT", "STRAFERIGHT"), 0, Input.get_axis("FORWARD", "BACK")).normalized()
	
	update_camera()
	
	# redoing the ENTIRE SYSTEM WITH A STATE MACHINE!!!!!!
	# decide state
	# Jump logic is handled within each state
	if Input.is_action_pressed("SLIDE") and (is_on_floor() or (is_on_wall() and velocity.length() >= 6)):
		state = "slide"
	else:
		if is_on_floor():
			state = "walk"
		else:
			state = "air"
			
	grapple_control()
	if grapple.state == "hooked":
		state = "hooked"
		
	# trigger buffer timer
	if Input.is_action_just_pressed("JUMP"):
		$BufferTimer.start()
		
	var movement = (transform.basis * direction_input).normalized()
	# General movement
	match state:
		"slide":
			if Input.is_action_just_pressed("SLIDE") or last_state != "slide":
				if !direction_input:
					direction_input = Vector3(0,0,-1)
				if velocity.length() >= SPEED * 1.5:
					slide_vector = transform.basis * (direction_input * velocity.length())
				else:
					slide_vector = (transform.basis * direction_input) * SPEED * 1.5
			if get_wall_normal():
				slide_vector = slide_vector.slide(get_wall_normal()) * Vector3(1, 0.98, 1)
			velocity.x = (movement.x * 0.8) + slide_vector.x
			velocity.z = (movement.z * 0.8) + slide_vector.z
			velocity += -get_wall_normal() * 0.6 # not too sticky so you can look away and bounce off
		"walk":
			air_movement_vector = Vector3(0,0,0)
			velocity.x = movement.x * SPEED
			velocity.z = movement.z * SPEED
		"air":
			if movement:
				if Vector2(velocity.x, velocity.z).length() >= SPEED * 2:
					# makes sure that you can't really accelerate (or decelerate, but that's a side effect)
					var new_velocity = (velocity + (movement * 0.7)).normalized() * (velocity.length())
					velocity.x = new_velocity.x
					velocity.z = new_velocity.z
				else:
					# change movement, lerp, add back to split up
					velocity -= air_movement_vector
					air_movement_vector.x = move_toward(air_movement_vector.x, movement.x * (SPEED * 0.5), AIR_ACCEL)
					air_movement_vector.z = move_toward(air_movement_vector.z, movement.z * (SPEED * 0.5), AIR_ACCEL)
					velocity += air_movement_vector
			else:
				velocity.x = move_toward(velocity.x, 0, AIR_FRICTION)
				velocity.z = move_toward(velocity.z, 0, AIR_FRICTION)
				
			# gravity
			velocity.y = move_toward(velocity.y, GRAVITY_MAX, GRAVITY_SPEED)
		"hooked":
			if velocity.length() >= grapple_vector.length():
				velocity -= grapple_vector
			grapple_vector = (grapple.global_position - global_position).normalized() * 30
			slide_vector = grapple_vector
			velocity += grapple_vector
	# jump
	if !$BufferTimer.is_stopped():
		if state == "slide":
			# Floor priority first in case you're touching both a floor and a wall
			var converted_slide_vector = (slide_vector.normalized() * 8)
			if is_on_floor():
				velocity += (Vector3(converted_slide_vector.x, slide_vector.y + 12, converted_slide_vector.z))
			else:
				velocity += ((get_wall_normal() * 16) + (Vector3(converted_slide_vector.x, slide_vector.y + 8, converted_slide_vector.z)))
		elif state == "walk":
			velocity.y += 16 
		elif state == "air" and is_on_wall():
			velocity += get_wall_normal() * 3 + Vector3(0,8,0)
		$BufferTimer.stop()
			
			
	# Checkpoints, death are checked asynchronously
	
	# set last movement
	last_state = state
		
	# Aesthetic stuff
	
	# oooo velocity particles
	# lowk vertical velocity shouldn't count
	if Vector2(velocity.x, velocity.z).length() >= 12:
		$VelocityParticles.emitting = true
		$VelocityParticles.amount = lerpf($VelocityParticles.amount, 4 + ((velocity.length()-12) / 4), 0.5) # i love interpolating
		$VelocityParticles.draw_pass_1.size.z = clampf(velocity.length() / 16, 0, 3)
		$VelocityParticles.look_at(Vector3(velocity.x + global_position.x, global_position.y, velocity.z + global_position.z), Vector3.UP)
	else:
		$VelocityParticles.emitting = false
	
	# camera down when slide, tilt cam if on wall or sliding in certain direction
	# height is broken until i change some stuff
	$Camera3D.rotation.z = lerp($Camera3D.rotation.z, -Input.get_axis("STRAFELEFT", "STRAFERIGHT") * (0.03 + (int("slide" in state) * 0.07) * int(is_on_floor())), 0.5)
	
	if "slide" in state:
		# $CollisionShape3D.shape.height = 1
		if is_on_floor():
			$Camera3D.position.y = lerp($Camera3D.position.y, -0.3, 0.5)
		else:
			if is_on_wall():
				$Camera3D.rotation.z += lerp($Camera3D.rotation.z, float(int($RayCast3DRight.is_colliding()) - int($RayCast3DLeft.is_colliding())) / (PI * 6), 0.3)
	else:
		# $CollisionShape3D.shape.height = 2
		$Camera3D.position.y = lerp($Camera3D.position.y, 0.733, 0.5)
	
	# Grapple rope
	if grapple.visible:
		line.mesh.size.z = abs(($Camera3D/WirePositionEnd.global_position - grapple.get_node("WirePositionEnd").global_position).length())
		line.global_position = lerp($Camera3D/WirePositionEnd.global_position, grapple.get_node("WirePositionEnd").global_position, 0.5)
		line.look_at(grapple.get_node("WirePositionEnd").global_position)
	line.visible = grapple.visible
	
	# Audio
	$AudioManager.audio_loop()

	move_and_slide()
	
	# update some globals
	Global.player_pos = global_position
	Global.player_velocity = velocity
	Global.player_state = state

func update_camera():
	var movement = Input.get_last_mouse_velocity() # local var nyehehehe
	rotate_y(-movement.x * SENSITIVITY)
	$Camera3D.rotation.x = clampf($Camera3D.rotation.x + -movement.y * SENSITIVITY, -PI/2, PI/2) # for some reason it defaults to rad??
	
func grapple_control():
	# check for throw grapple command
	if Input.is_action_just_pressed("HOOK"):
		if grapple.state == "disabled":
			grapple.state = "active"
			grapple_vector = Vector3(0,0,0)
			grapple.global_rotation = $Camera3D.global_rotation
			grapple.global_position = global_position + Vector3(0,0.733,0) + (Vector3(0,0,0) * $Camera3D.global_transform.basis)
			grapple.velocity = $Camera3D.global_transform.basis * Vector3(0,0,-128)
			line.visible = true
		else:
			grapple.die()
	if grapple.global_position.distance_to(global_position) >= 30:
		grapple.die()
	
func death(_really_useless_value_that_they_put_here_idk_why):
	if is_physics_processing():
		set_physics_process(false)
		get_tree().paused = false
		await Global.screen_transition("wipe_on")
		global_position = respawn_checkpoint
		grapple.global_position = global_position
		grapple.state = "disabled"
		velocity = Vector3(0,0,0)
		set_physics_process(true)
		await Global.screen_transition("wipe_off")
		
func _on_checkpoint(area) -> void:
	if respawn_checkpoint != area.global_position:
		respawn_checkpoint = area.global_position
		checkpoint_reached.emit()
