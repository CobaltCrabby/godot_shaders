extends ColorRect

@export var speed: float
var theta = 0

func _process(delta):
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("quality", sin(theta) * 50)
	theta += delta * speed
