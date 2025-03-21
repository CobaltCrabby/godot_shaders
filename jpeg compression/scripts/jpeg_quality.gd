@tool
extends CompositorEffect
class_name JPEGCompression

var rd: RenderingDevice
var shader: RID
var pipeline: RID
@export_range(0, 100) var quality: int

func _init():
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()

	var shader_file := load("res://jpeg compression/shaders/jpeg_compression.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()

	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		return

	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		return

	pipeline = rd.compute_pipeline_create(shader)
	if !pipeline.is_valid():
		return

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			rd.free_rid(shader)

# copied from the docs
func _render_callback(p_effect_callback_type, p_render_data):
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
		var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			var size = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return

			var x_groups = (size.x - 1) / 8 + 1
			var y_groups = (size.y - 1) / 8 + 1
			var z_groups = 1

			var push_constant: PackedFloat32Array = PackedFloat32Array()
			push_constant.push_back(size.x) #image size
			push_constant.push_back(size.y)
			push_constant.push_back(quality) # quality
			push_constant.push_back(1) # color compression

			# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono. (IDK WHAT THIS MEANS lmao)
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				var input_image = render_scene_buffers.get_color_layer(view)

				var uniform: RDUniform = RDUniform.new()
				uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				uniform.binding = 0
				uniform.add_id(input_image)
				var uniform_set = UniformSetCacheRD.get_cache(shader, 0, [ uniform ])

				var compute_list:= rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
				rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
				rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
