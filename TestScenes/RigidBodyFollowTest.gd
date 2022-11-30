extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var target = get_parent().global_transform.origin - 0.7*Vector3(0,1,0) - 0.5*get_parent().global_transform.basis.z
	var dir = target - global_transform.origin
	apply_central_impulse(10*dir)
	pass
