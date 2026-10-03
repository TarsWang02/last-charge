class_name ModelUtil
## Helpers for AI-generated models whose scale/pivot are unpredictable.

static func combined_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var inv := root.global_transform.affine_inverse()
	for v in root.find_children("*", "VisualInstance3D", true, false):
		var a: AABB = (inv * v.global_transform) * v.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box

## Scale uniformly to `height` (0 = keep) and put the feet at y=0, centred on x/z.
static func fit(root: Node3D, height: float) -> void:
	var box := combined_aabb(root)
	if box.size.y <= 0.0001:
		return
	var s := height / box.size.y if height > 0.0 else 1.0
	root.scale = Vector3.ONE * s
	var c := box.get_center()
	root.position = Vector3(-c.x * s, -box.position.y * s, -c.z * s)
