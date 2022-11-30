extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_reflectArea_body_entered(body):
	
	if body.get_class() == "RigidBody": #cant apply forces to other bodies
		if body.get("picked_up_by") == null:
			#cheap quick way to make sure I dont bounce myself into oblivion
			return
		#push the body with a force in the direction of me to body
		var dir = body.global_transform.origin - global_transform.origin
		var strength = 100.0 #give it a constant strength for now
		body.apply_central_impulse(body.mass*strength*dir)
	pass # Replace with function body.
