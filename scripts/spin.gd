extends Node3D

@export var speed: float = 1.0
@export var rotation_axis: Vector3 = Vector3.UP

func _process(delta):
	rotate(rotation_axis, speed * delta)
