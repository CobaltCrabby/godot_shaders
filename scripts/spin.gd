extends Node3D

@export var speed: float
@export var rotation_axis: Vector3

func _process(delta):
	rotate(rotation_axis, speed * delta)
