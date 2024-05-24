extends Node

@export var texture_rect: TextureRect

func _ready():
	var rd := RenderingServer.create_local_rendering_device()
	var bobadog := load("res://pixel water/textures/bobadog.png")
	var texture = bobadog.get_image()
	var texture_data: PackedByteArray = texture.get_data()

	var format := RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB
	var resolution := get_viewport().get_visible_rect().size
	format.width = 123
	format.height = 128
	format.usage_bits = \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + \
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var rid := rd.texture_create(format, RDTextureView.new(), [texture_data])

	var shader_file := load("res://compute shaders/shaders/compute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)

	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(rid)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0)

	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, ceil(resolution.x / 8), ceil(resolution.y / 8), 1)
	rd.compute_list_end()

	rd.submit()
	rd.sync()

	var output_bytes := rd.texture_get_data(rid, 0)
	var output := Image.create_from_data(resolution.x, resolution.y, false, Image.FORMAT_L8, output_bytes)
	var island_tex := ImageTexture.create_from_image(output)
	texture_rect.texture = island_tex
