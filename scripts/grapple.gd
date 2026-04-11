extends CharacterBody3D

var state : String = "disabled"

# lil baby script
func _physics_process(_delta):
	match state:
		"active":
			visible = true
			if move_and_slide():
				look_at(global_position - get_last_slide_collision().get_normal(), Vector3(0,0.9999, 0.005)) # cant ignore that fuckass warning
				reparent(get_last_slide_collision().get_collider()) # for moving objects
				state = "hooked"
				velocity = Vector3(0,0,0)
		"hooked":
			if (len($RemoveCheck.get_overlapping_areas()) != 0 or len($RemoveCheck.get_overlapping_bodies()) != 0):
				state = "disabled"
		"disabled":
			if visible:
				global_position -= (global_position - Global.player_pos).normalized() * 2
				if (len($RemoveCheck.get_overlapping_areas()) != 0 or len($RemoveCheck.get_overlapping_bodies()) != 0):
					visible = false
func die():
	state = "disabled"
	
