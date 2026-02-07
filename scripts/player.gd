extends CharacterBody3D

# powers of 2 rahhhhhh
const SPEED = 4
const GRAVITY_MAX = -16

func _physics_process(_delta):
	var direction = Input.get_vector("STRAFELEFT", "STRAFERIGHT", "FORWARD", "BACK").normalized()*3
	
	# 2d x,y is 3d x,z
	velocity.x = direction.x * SPEED
	velocity.z = direction.y * SPEED
	
	if !is_on_floor():
		velocity.y = move_toward(velocity.y, GRAVITY_MAX, 2)
		
	if Input.is_action_pressed("JUMP") and is_on_floor():
		velocity.y += 32
		
	move_and_slide()

func update_camera():
	pass
