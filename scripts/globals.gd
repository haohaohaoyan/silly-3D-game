extends Node

var sfx_volume : float = 1
var fov_base : float = 95
var player_pos : Vector3 = Vector3(0,0,0)
var player_velocity : Vector3 = Vector3(0,0,0)
var player_state : String = ""

func _ready():
	get_tree().get_root().add_child.call_deferred(load("res://scenes/screenwipe.tscn").instantiate()) # i'm pretty lazy
	
func screen_transition(play: String):
	var screenwipe_player = get_tree().get_root().get_node("Screenwipe/AnimationPlayer")
	screenwipe_player.play("RESET")
	screenwipe_player.stop()
	screenwipe_player.clear_queue()
	screenwipe_player.play(play)
	await screenwipe_player.animation_finished
			
var fade_tween : Tween # for reuse
func tooltip(_empty, string: String): #empty var because signals default to forcing one down the function's mouth
	var tooltip_text = get_tree().get_root().get_node("Game/BottomHUD/ToolTip")
	tooltip_text.text = string
	tooltip_text.visible = true
	tooltip_text.modulate.a = 1
	# funny fade out tween!!111!!111!!!!!
	if fade_tween:
		fade_tween.kill()
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(tooltip_text, "modulate:a", 0, 5)
	fade_tween.tween_callback(fade_tween.kill) #ok so now it's always visible but 0 alpha bc lambda functions are being petty
# hmmmmm very efficient definitely
	
