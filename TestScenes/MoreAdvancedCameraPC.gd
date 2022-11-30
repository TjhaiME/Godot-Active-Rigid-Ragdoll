extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func reset_rigidBodies(pos):
	global_transform.origin = pos
	$Camera.translation = 1.368*Vector3(0,1,0)
	for index in $Camera.get_child_count():
		var child = $Camera.get_child(index)
		child.transform = Transform.IDENTITY
