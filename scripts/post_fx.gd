extends CanvasLayer
## Diorama post process. Drop scenes/post_fx.tscn into any level and set `player_path`
## (a node with a `charge` 0..1 property) to drive the low-power look.

@export var player_path: NodePath
@export var power_loss_below := 0.5 ## charge where the power-loss look starts
@export var enabled := true:
	set(v):
		enabled = v
		if is_node_ready():
			$Screen.visible = v

@onready var mat: ShaderMaterial = $Screen.material
var _loss := 0.0
var loss_cap := 1.0  ## a scene can ease the low-power look off for a moment (the clothesline's slow look)

func _ready() -> void:
	$Screen.visible = enabled

func _process(delta: float) -> void:
	var p := get_node_or_null(player_path)
	if p == null or not "charge" in p:
		return
	var target := minf(clampf((power_loss_below - float(p.charge)) / power_loss_below, 0.0, 1.0), loss_cap)
	_loss = lerpf(_loss, target, 1.0 - exp(-3.0 * delta))
	mat.set_shader_parameter("power_loss", _loss)
