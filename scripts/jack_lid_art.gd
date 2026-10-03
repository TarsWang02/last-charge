extends Node3D
## Decorative lid follows the existing clown animation without changing gameplay collision.
func _process(_delta: float) -> void:
    var head: Node3D = get_parent().get_parent().get_node("JackHead")
    var openness := clampf((head.position.y / 9.0 - 0.07) / 0.16, 0.0, 1.0)
    rotation.x = -1.85 * openness
