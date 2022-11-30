extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#var sparkPreload = preload("res://addons/rigidRagdoll/Items/Effects/Sparks.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_sparkArea_body_entered(body):
	#spawn sparks
	var sparks = $Sparks/Particles
	sparks.emitting = true
	pass # Replace with function body.
