extends CharacterBody3D

# powers of 2 rahhhhhh
const SPEED = 8
const GRAVITY_MAX = -32
const GRAVITY_SPEED = 0.5
const SENSITIVITY = 0.00007 # what in the name of
const AIR_ACCEL = 0.5
const AIR_FRICTION = 0.1

var slide_state 
var last_movement_state
var slide_vector

func _physics_process(_delta):
	var direction_input = Input.get_vector("STRAFELEFT", "STRAFERIGHT", "FORWARD", "BACK").normalized()
	
	update_camera()
	
	# act based on state, then rotate. direction.x is left/right, direction.y is forward/back
	# it's split based on movement types
	
	slide_state = false # only ONE case can have the slide
	if Input.is_action_pressed("SLIDE"): 
		if is_on_floor() or (is_on_wall() and velocity.length() >= 6):
			slide_state = true
	
	if slide_state:
		if Input.is_action_just_pressed("SLIDE") or (last_movement_state == "floor" or last_movement_state == "air"):
			if velocity.length() >= 12:
				slide_vector = velocity
			else:
				if direction_input:
					slide_vector = (transform.basis * Vector3(direction_input.x, 0, direction_input.y)) * SPEED * 1.5
				else:
					slide_vector = (transform.basis * Vector3(0,0,-1)).normalized() * SPEED * 1.5
		var movement = slide_vector + (transform.basis * Vector3(direction_input.x, 0, direction_input.y)).normalized() / 2
		velocity.x = movement.x
		velocity.z = movement.z
		velocity += -get_wall_normal()
	else:
		# reset slide vector 
		var movement = (transform.basis * Vector3(direction_input.x, 0, direction_input.y)).normalized() * SPEED
		if is_on_floor():
			velocity.x = movement.x
			velocity.z = movement.z
		else:
			if movement and velocity.length() <= SPEED:
				velocity.x = move_toward(velocity.x, movement.x, AIR_ACCEL)
				velocity.z = move_toward(velocity.z, movement.z, AIR_ACCEL)
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
				velocity += (Vector3(slide_vector.x, slide_vector.y + 8, slide_vector.z))
			else:
				velocity += (get_wall_normal() * 16) + (Vector3(slide_vector.x, slide_vector.y + 8, slide_vector.z))
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
			
	# set last movement
	if slide_state:
		if is_on_floor():
			last_movement_state = "slide_floor"
		elif is_on_wall():
			last_movement_state = "slide_wall"
	else:
		if is_on_floor():
			last_movement_state = "floor"
		else:
			last_movement_state = "air"
		
	# Aesthetic stuff
	
	# camera down when slide, tilt cam if on wall
	if slide_state:
		# $CollisionShape3D.shape.height = 1
		$Camera3D.position.y = -0.3
	else:
		# $CollisionShape3D.shape.height = 2
		$Camera3D.position.y = 0.363
		
	move_and_slide()

func update_camera():
	var movement = Input.get_last_mouse_velocity() # local var
	rotate_y(-movement.x * SENSITIVITY)
	$Camera3D.rotation.x = clampf($Camera3D.rotation.x + -movement.y * SENSITIVITY, -PI/2, PI/2) # for some reason it defaults to rad??
