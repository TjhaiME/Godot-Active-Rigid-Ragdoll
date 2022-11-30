extends Camera


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var faction = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_camera(delta)

func move_camera(delta):
	if Input.is_action_pressed("ui_left"):
		global_rotate(Vector3(0,1,0), delta)
		#print("my Detect area = ", $Spatial/DetectArea)
	if Input.is_action_pressed("ui_right"):
		global_rotate(Vector3(0,1,0), -delta)
	if Input.is_action_pressed("ui_up"):
		var dir = global_transform.basis.z
		global_translate(-dir*delta*3)
	if Input.is_action_pressed("ui_down"):
		var dir = global_transform.basis.z
		global_translate(dir*delta*3)
	if Input.is_action_pressed("ui_focus_next"):
		if Input.is_action_pressed("ui_up"):
			var dir = global_transform.basis.x
			global_rotate(-dir,delta*3)#Vector3(1,0,0),
		if Input.is_action_pressed("ui_down"):
			var dir = global_transform.basis.x
			global_rotate(dir,delta*3)
