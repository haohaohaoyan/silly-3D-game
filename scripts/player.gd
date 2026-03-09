extends CharacterBody3D

# powers of 2 rahhhhhh
const SPEED = 8
const GRAVITY_MAX = -32
const GRAVITY_SPEED = 0.5
const SENSITIVITY = 0.00007 # what in the name of
const AIR_ACCEL = 0.2
const AIR_FRICTION = 0.1

var slide_state 
var last_movement_state: Dictionary
var slide_vector

@onready var grapple = owner.get_node("Grapple")

func _physics_process(_delta):
	var direction_input = Vector3(Input.get_axis("STRAFELEFT", "STRAFERIGHT"), 0, Input.get_axis("FORWARD", "BACK")).normalized()
	
	update_camera()
	
	# act based on state, then rotate. direction.x is left/right, direction.y is forward/back
	# it's split based on movement types

	if Input.is_action_pressed("SLIDE") and (is_on_floor() or (is_on_wall() and velocity.length() >= 6)): 
		slide_state = true
	else:
		slide_state = false
	
	if slide_state:
		if Input.is_action_just_pressed("SLIDE") or !last_movement_state["slide_state"]:
			if direction_input:
				if velocity.length() >= 12:
					slide_vector = transform.basis * (direction_input * velocity.length())
				else:
					slide_vector = (transform.basis * direction_input) * SPEED * 1.5
			else:
				slide_vector = (transform.basis * Vector3(0,0,-1)).normalized() * SPEED * 1.5
				
		if get_wall_normal():
			slide_vector = slide_vector.slide(get_wall_normal())
		var movement = slide_vector + (transform.basis * direction_input).normalized() * 0.8
		velocity.x = movement.x
		velocity.z = movement.z
		velocity += -get_wall_normal() * 0.6 # not too sticky so you can look away and bounce off
	else:
		# reset slide vector 
		var movement = (transform.basis * direction_input).normalized() * SPEED
		if is_on_floor():
			velocity.x = movement.x
			velocity.z = movement.z
		else:
			if movement:
				velocity.x = move_toward(velocity.x, velocity.x + movement.x * 2, AIR_ACCEL)
				velocity.z = move_toward(velocity.z, velocity.x + movement.z * 2, AIR_ACCEL)
			else:
				velocity.x = move_toward(velocity.x, 0, AIR_FRICTION)
				velocity.z = move_toward(velocity.z, 0, AIR_FRICTION)
	
	# Jump
	# trigger buffer timer
	if Input.is_action_just_pressed("JUMP"):
		$BufferTimer.start()
	
	if !$BufferTimer.is_stopped():
		if slide_state:
			# Floor priority first in case you're touching both a floor and a wall
			if is_on_floor():
				velocity += (Vector3((slide_vector.normalized() * 8).x, slide_vector.y + 12, (slide_vector.normalized() * 8).z))
			else:
				velocity += ((get_wall_normal() * 16) + (Vector3((slide_vector.normalized() * 8).x, slide_vector.y + 8, (slide_vector.normalized() * 8).z)))
			$BufferTimer.stop()
		elif is_on_floor():
			velocity.y += 16 
			$BufferTimer.stop()
			
	# Gravity
	if !is_on_floor():
		if slide_state:
			velocity.y = move_toward(velocity.y,0, 1)
		else:
			velocity.y = move_toward(velocity.y, GRAVITY_MAX, GRAVITY_SPEED)
			
	# set last movement (fancy dict)
	if is_on_wall():
		last_movement_state = {"slide_state": true, "wall_normal": get_wall_normal()}
	else:
		if is_on_floor():
			last_movement_state = {"slide_state": slide_state, "wall_normal": null}
		else:
			last_movement_state["slide_state"] = false
		
	# after movement, process the grapple thingamabobber
	grapple_control()
		
	# Aesthetic stuff
	
	# oooo velocity particles
	# lowk vertical velocity shouldn't count
	if Vector2(velocity.x, velocity.z).length() >= 12:
		$SlideParticles.emitting = true
		$SlideParticles.amount = lerpf($SlideParticles.amount, 4 + ((velocity.length()-12) / 4), 0.5) # i love interpolating
		$SlideParticles.draw_pass_1.size.z = clampf(velocity.length() / 16, 0, 3)
		$SlideParticles.look_at(Vector3(velocity.x + global_position.x, global_position.y, velocity.z + global_position.z), Vector3.UP)
	else:
		$SlideParticles.emitting = false
	
	# camera down when slide, tilt cam if on wall or sliding in certain direction
	# height is broken until i change some stuff
	$Camera3D.rotation.z = lerp($Camera3D.rotation.z, -Input.get_axis("STRAFELEFT", "STRAFERIGHT") * (0.03 + (int(slide_state) * 0.07) * int(is_on_floor())), 0.5)
	
	if slide_state:
		# $CollisionShape3D.shape.height = 1
		if is_on_floor():
			$Camera3D.position.y = lerp($Camera3D.position.y, -0.3, 0.5)
		else:
			if is_on_wall():
				$Camera3D.rotation.z += lerp($Camera3D.rotation.z, float(int($RayCast3DRight.is_colliding()) - int($RayCast3DLeft.is_colliding())) / (PI * 6), 0.3)
	else:
		# $CollisionShape3D.shape.height = 2
		$Camera3D.position.y = lerp($Camera3D.position.y, 0.733, 0.5)
	
	# Audio
	$AudioManager.audio_loop()

	move_and_slide()
	
func update_camera():
	var movement = Input.get_last_mouse_velocity() # local var nyehehehe
	rotate_y(-movement.x * SENSITIVITY)
	$Camera3D.rotation.x = clampf($Camera3D.rotation.x + -movement.y * SENSITIVITY, -PI/2, PI/2) # for some reason it defaults to rad??
	
func grapple_control():
	# check for throw grapple command
	if Input.is_action_just_pressed("HOOK"):
		grapple.set_physics_process(true)
		grapple.visible = true
		grapple.global_rotation = $Camera3D.global_rotation
		grapple.global_position = global_position + Vector3(0,0.733,0) + (Vector3(0,0,0) * $Camera3D.global_transform.basis)
		grapple.velocity = $Camera3D.global_transform.basis * Vector3(0,0,-128)
