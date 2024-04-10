extends MultiMeshInstance3D

@export var mesh: Mesh
@export var height_map: Texture2D
@export var grass_map: Texture2D

func _ready():
	
	multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.instance_count = 60000
	multimesh.visible_instance_count = 60000
	
	await height_map.changed
	await grass_map.changed
	var rng = RandomNumberGenerator.new();
	var r_x = 0.0;
	var r_y = 0.0;
	var random = Color(0.0, 0.0, 0.0, 0.0)
	for i in multimesh.visible_instance_count:
		var count = floor(i / 3)
		
		var x = count % 200 / 2 - 50 
		var z = floor(count / 200) - 50
		
		rng.seed = count
		var seed2 = rng.randi()
		r_x = rng.randf_range(-0.25, 0.25)
		rng.seed = seed2
		r_y = rng.randf_range(-0.25, 0.25)
		
		var position = Vector3(x, 0.5, z) + Vector3(r_x, 0.0, r_y)
		var transform = Transform3D(Basis(Vector3.UP, PI/3 * (i % 3)), position)
		
		var height = height_map.get_image().get_pixel((x / 100.0 + 0.5) * 512, (z / 100.0 + 0.5) * 512)
		var grass = grass_map.get_image().get_pixel((x / 100.0 + 0.5) * 512, (z / 100.0 + 0.5) * 512)
		random.r = count + 1
		random.g = PI/3 * (i % 3)
		random.b = height.r
		random.a = grass.r
		
		multimesh.set_instance_transform(i, transform)
		multimesh.set_instance_custom_data(i, random)
