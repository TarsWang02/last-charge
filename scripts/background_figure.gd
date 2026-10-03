extends Node3D
## The seated background figure would occlude the maze's overhead view.
func _process(_delta: float) -> void:
    var room := get_parent().get_parent()
    if "player" in room and is_instance_valid(room.player):
        visible = not room.player.top_down
