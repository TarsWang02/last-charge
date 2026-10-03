extends CanvasLayer
## Battery bar, FPS counter, settings panel (shown while the mouse is released).

@export var player_path: NodePath
@onready var battery_bar: ProgressBar = $Battery
@onready var battery_label: Label = $Battery/Label
@onready var fps_label: Label = $FPS
@onready var settings: PanelContainer = $Settings
@onready var shadow_opt: OptionButton = $Settings/VBox/Shadow
@onready var scale_slider: HSlider = $Settings/VBox/Scale
@onready var scale_label: Label = $Settings/VBox/ScaleLabel

func _ready() -> void:
	get_node(player_path).battery_changed.connect(_on_battery)
	for n in ["Low", "Medium", "High"]:
		shadow_opt.add_item("Shadows: " + n)
	shadow_opt.select(1)
	shadow_opt.item_selected.connect(apply_shadow_quality)
	scale_slider.value_changed.connect(apply_render_scale)
	apply_shadow_quality(1)
	apply_render_scale(scale_slider.value)

func _on_battery(v: float, on: bool) -> void:
	battery_bar.value = v
	battery_label.text = "LIGHT %d%%%s" % [int(v), "" if on else "  [OFF]"]

func apply_shadow_quality(q: int) -> void:
	var sizes := [1024, 2048, 4096]
	var filt := [RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_HIGH]
	get_viewport().positional_shadow_atlas_size = sizes[q]
	RenderingServer.positional_soft_shadow_filter_set_quality(filt[q])
	RenderingServer.directional_soft_shadow_filter_set_quality(filt[q])

func apply_render_scale(v: float) -> void:
	get_viewport().scaling_3d_scale = v
	scale_label.text = "Render scale: %d%%" % int(v * 100)

func _process(_d: float) -> void:
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	settings.visible = Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
