class_name TvScreen
extends Node3D
## The living-room CRT showing a live pixel game (TvGame in a 320 x 240 SubViewport). This node sits at
## the centre of the glass, facing +Z (into the room). Also owns the screen effects for the
## "pulled into the TV" moment: static, a white flash, and the camera spot that fills the view with it.

const SHADER := preload("res://shaders/crt_screen.gdshader")
const RES := Vector2i(320, 240)

@export var size := Vector2(4.32, 3.42)  ## glass size (units)

var game: TvGame
var mat: ShaderMaterial
var viewport: SubViewport

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = RES
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.snap_2d_transforms_to_pixel = true
	add_child(viewport)
	game = TvGame.new()
	viewport.add_child(game)
	var quad := QuadMesh.new()
	quad.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("screen_tex", viewport.get_texture())
	mat.set_shader_parameter("res", Vector2(RES))
	mi.material_override = mat
	add_child(mi)

## Where a camera must stand so the glass fills the view height (with a thin rim of the TV around it).
func camera_spot(cam_fov_deg: float) -> Transform3D:
	var d := (size.y * 0.5 * 1.06) / tan(deg_to_rad(cam_fov_deg) * 0.5)
	var p := global_transform * Vector3(0, 0, d)
	return Transform3D(global_basis, p)

## A burst of static with a white flash (enter / exit the screen).
func zap(time := 0.5) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 2.5, 0.0, time).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): mat.set_shader_parameter("static_amt", v), 0.9, 0.0, time * 1.4)
