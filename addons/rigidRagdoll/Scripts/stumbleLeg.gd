extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var floorBodies = []
var touchingFloor = false

# Called when the node enters the scene tree for the first time.
func _ready():
	print( " floorBodies = ", floorBodies)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _integrate_forces(state):
	#return
	if touchingFloor:
		dampen_ang_movement(state)

func dampen_ang_movement(state):
	var stop_speed = 0.8
	state.angular_velocity.x = lerp(state.angular_velocity.x,0,stop_speed)
	state.angular_velocity.y = lerp(state.angular_velocity.y,0,stop_speed)
	state.angular_velocity.z = lerp(state.angular_velocity.z,0,stop_speed)

#NOTES:
#need to have it resist angular motion when it is touching the floor


func _on_FootArea_body_entered(body):
	#print(name, ": floor entered = ", body, " floorBodies = ", floorBodies)
	if body in floorBodies:
		return
	floorBodies.append(body)
	touchingFloor = true
	pass # Replace with function body.


func _on_FootArea_body_exited(body):
	#print(name, ": ! floor exited = ", body, " floorBodies = ", floorBodies)
	if body in floorBodies:
		floorBodies.erase(body)
	if floorBodies.size() == 0:
		touchingFloor = false
	pass # Replace with function body.
