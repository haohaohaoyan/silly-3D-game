extends CharacterBody3D

# powers of 2 rahhhhhh
const SPEED = 8
const GRAVITY_MAX = -32
const GRAVITY_SPEED = 0.5
const SENSITIVITY = 0.00007 # what in the name of
const AIR_ACCEL = 0.2
const AIR_FRICTION = 0.1

var slide_state : bool
var last_movement_state: Dictionary
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
	
	# act based on state, then rotate. direction.x is left/right, direction.y is forward/back
	# it's split based on movement types

	if Input.is_action_pressed("SLIDE") and (is_on_floor() or (is_on_wall() and velocity.length() >= 6)): 
		slide_state = true
	else:
		slide_state = false
	
	if slide_state:
		if Input.is_action_just_pressed("SLIDE") or !last_movement_state["slide_state"]:
			if direction_input:
				if velocity.length() >= SPEED * 1.5:
					slide_vector = transform.basis * (direction_input * velocity.length())
				else:
					slide_vector = (transform.basis * direction_input) * SPEED * 1.5
			else:
				if velocity.length() >= SPEED * 1.5:
					slide_vector = (transform.basis * Vector3(0,0,-1)).normalized() * velocity.length()
				else:
					slide_vector = (transform.basis * Vector3(0,0,-1)).normalized() * SPEED * 1.5
		if get_wall_normal():
			slide_vector = slide_vector.slide(get_wall_normal()) * Vector3(1, 0.98, 1)
		var movement = slide_vector + (transform.basis * direction_input).normalized() * 0.8
		velocity.x = movement.x
		velocity.z = movement.z
		velocity += -get_wall_normal() * 0.6 # not too sticky so you can look away and bounce off
	else:
		# reset slide vector 
		var movement = (transform.basis * direction_input).normalized() * SPEED
		if is_on_floor() and !grapple.is_hooked:
			air_movement_vector = Vector3(0,0,0)
			velocity.x = movement.x
			velocity.z = movement.z
		else:
			if movement:
				# change movement, lerp, add back to split up
				velocity -= air_movement_vector
				if Vector2(velocity.x, velocity.z).length() >= SPEED:
					air_movement_vector = (transform.basis * Vector3(0,0,direction_input.x * SPEED))
				else:
					air_movement_vector.x = move_toward(air_movement_vector.x, movement.x, AIR_ACCEL)
					air_movement_vector.z = move_toward(air_movement_vector.z, movement.z, AIR_ACCEL)
				velocity += air_movement_vector
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
			var converted_slide_vector = (slide_vector.normalized() * 8)
			if is_on_floor():
				velocity += (Vector3(converted_slide_vector.x, slide_vector.y + 12, converted_slide_vector.z))
			else:
				velocity += ((get_wall_normal() * 16) + (Vector3(converted_slide_vector.x, slide_vector.y + 8, converted_slide_vector.z)))
			$BufferTimer.stop()
		elif is_on_floor():
			velocity.y += 16 
			$BufferTimer.stop()
			
	# Gravity
	if !is_on_floor() and !grapple.is_hooked and slide_state == false:
		velocity.y = move_toward(velocity.y, GRAVITY_MAX, GRAVITY_SPEED)
		
	# Checkpoints are checked asynchronously
	
	# Check for death-related things
	if len($DeathCollision.get_overlapping_areas()) > 0 or len($DeathCollision.get_overlapping_bodies()) > 0:
		death()
	
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
		$VelocityParticles.emitting = true
		$VelocityParticles.amount = lerpf($VelocityParticles.amount, 4 + ((velocity.length()-12) / 4), 0.5) # i love interpolating
		$VelocityParticles.draw_pass_1.size.z = clampf(velocity.length() / 16, 0, 3)
		$VelocityParticles.look_at(Vector3(velocity.x + global_position.x, global_position.y, velocity.z + global_position.z), Vector3.UP)
	else:
		$VelocityParticles.emitting = false
	
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
		grapple.is_hooked = false
		if !grapple.visible:
			grapple_vector = Vector3(0,0,0)
			grapple.visible = true
			grapple.global_rotation = $Camera3D.global_rotation
			grapple.global_position = global_position + Vector3(0,0.733,0) + (Vector3(0,0,0) * $Camera3D.global_transform.basis)
			grapple.velocity = $Camera3D.global_transform.basis * Vector3(0,0,-128)
			line.visible = true
		else:
			grapple.visible = false
		
	if grapple.visible:
		line.mesh.size.z = abs(($Camera3D/WirePositionEnd.global_position - grapple.get_node("WirePositionEnd").global_position).length())
		line.global_position = lerp($Camera3D/WirePositionEnd.global_position, grapple.get_node("WirePositionEnd").global_position, 0.5)
		line.look_at(grapple.get_node("WirePositionEnd").global_position)
		if grapple.is_hooked:
			if velocity.length() >= grapple_vector.length():
				velocity -= grapple_vector
			grapple_vector = (grapple.global_position - global_position).normalized() * 30
			slide_vector = grapple_vector
			velocity += grapple_vector
		if grapple.global_position.distance_to(global_position) >= 60:
			grapple.die()
	else:
		line.visible = false
		
func death():
	global_position = respawn_checkpoint
	grapple.global_position = global_position
	grapple.is_hooked = false
	grapple.visible = false
	velocity = Vector3(0,0,0)
		
func _on_checkpoint(area) -> void:
	if respawn_checkpoint != area.global_position:
		respawn_checkpoint = area.global_position
		checkpoint_reached.emit()
