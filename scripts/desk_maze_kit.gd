class_name DeskMazeKit
extends RefCounted
## Real metre dimensions; bottom-centre origins. Missing assets remain reviewable.
const ITEMS := [
	{"id": "textbook", "group": "A1", "glb_path": "res://assets/models/props/prop_desk_textbook.glb", "size_m": Vector3(0.11666700, 0.08000000, 0.02300000), "weight": 2},
	{"id": "calculator", "group": "A1", "glb_path": "res://assets/models/props/prop_desk_calculator.glb", "size_m": Vector3(0.11666700, 0.03900000, 0.02600000), "weight": 1},
	{"id": "tape_dispenser", "group": "A1", "glb_path": "res://assets/models/props/prop_desk_tape_dispenser.glb", "size_m": Vector3(0.11666700, 0.07100000, 0.02600000), "weight": 1},
	{"id": "book_stack", "group": "A2", "glb_path": "res://assets/models/props/prop_desk_book_stack.glb", "size_m": Vector3(0.23333301, 0.03900000, 0.02600000), "weight": 2},
	{"id": "fallen_books", "group": "A3", "glb_path": "res://assets/models/props/prop_desk_fallen_books.glb", "size_m": Vector3(0.34999999, 0.05200000, 0.02600000), "weight": 2},
	{"id": "pencil_pouch", "group": "A2", "glb_path": "res://assets/models/props/prop_desk_pencil_pouch.glb", "size_m": Vector3(0.23333301, 0.04550000, 0.03000000), "weight": 1},
	{"id": "upright_ruler", "group": "A2", "glb_path": "res://assets/models/props/prop_desk_upright_ruler.glb", "size_m": Vector3(0.23333301, 0.04000000, 0.01410000), "weight": 1},
	{"id": "ruler_exercise", "group": "A3", "glb_path": "res://assets/models/props/prop_desk_ruler_exercise.glb", "size_m": Vector3(0.34999999, 0.03800000, 0.02500000), "weight": 1},
	{"id": "open_book", "group": "A_stack", "glb_path": "res://assets/models/props/prop_desk_open_book.glb", "size_m": Vector3(0.06800000, 0.00700000, 0.06000000), "weight": 1},
	{"id": "cartridge", "group": "A_stack", "glb_path": "res://assets/models/props/prop_desk_cartridge.glb", "size_m": Vector3(0.03200000, 0.00920000, 0.02400000), "weight": 1},
	{"id": "pencil_pot", "group": "B", "glb_path": "res://assets/models/props/prop_desk_pencil_pot.glb", "size_m": Vector3(0.02600000, 0.04750000, 0.02600000), "weight": 1},
	{"id": "mug", "group": "B", "glb_path": "res://assets/models/props/prop_desk_mug.glb", "size_m": Vector3(0.02800000, 0.03286603, 0.02600000), "weight": 1},
	{"id": "soda_can", "group": "B", "glb_path": "res://assets/models/props/prop_desk_soda_can.glb", "size_m": Vector3(0.02800000, 0.05650000, 0.02800000), "weight": 1},
	{"id": "alarm_clock", "group": "B_tall", "glb_path": "res://assets/models/props/prop_desk_alarm_clock.glb", "size_m": Vector3(0.02700000, 0.08900000, 0.02700000), "weight": 1},
	{"id": "ruler_pot", "group": "B_tall", "glb_path": "res://assets/models/props/prop_desk_ruler_pot.glb", "size_m": Vector3(0.02600000, 0.14000000, 0.02600000), "weight": 1},
	{"id": "exam", "group": "C", "glb_path": "res://assets/models/props/prop_desk_exam.glb", "size_m": Vector3(0.06800000, 0.00105000, 0.08400000), "weight": 2},
	{"id": "homework", "group": "C", "glb_path": "res://assets/models/props/prop_desk_homework.glb", "size_m": Vector3(0.06800000, 0.00105000, 0.08400000), "weight": 2},
	{"id": "birthday_card", "group": "C", "glb_path": "res://assets/models/props/prop_desk_birthday_card.glb", "size_m": Vector3(0.06800000, 0.00105000, 0.08400000), "weight": 1},
	{"id": "certificate", "group": "C", "glb_path": "res://assets/models/props/prop_desk_certificate.glb", "size_m": Vector3(0.06800000, 0.00105000, 0.08400000), "weight": 1},
	{"id": "broken_edge", "group": "D", "glb_path": "res://assets/models/props/prop_desk_broken_edge.glb", "size_m": Vector3(0.11666700, 0.00600000, 0.00850000), "weight": 1},
	{"id": "splinter_corner", "group": "D", "glb_path": "res://assets/models/props/prop_desk_splinter_corner.glb", "size_m": Vector3(0.01800000, 0.00850000, 0.00900000), "weight": 1},
	{"id": "pencil_shaving", "group": "E", "glb_path": "res://assets/models/props/prop_desk_pencil_shaving.glb", "size_m": Vector3(0.01200000, 0.00080000, 0.00600000), "weight": 1},
	{"id": "paperclip", "group": "E", "glb_path": "res://assets/models/props/prop_desk_paperclip.glb", "size_m": Vector3(0.00828284, 0.00069282, 0.01568284), "weight": 1},
	{"id": "paper_ball", "group": "E", "glb_path": "res://assets/models/props/prop_desk_paper_ball.glb", "size_m": Vector3(0.01236375, 0.01170000, 0.01040000), "weight": 1},
	{"id": "pencil_stub", "group": "E", "glb_path": "res://assets/models/props/prop_desk_pencil_stub.glb", "size_m": Vector3(0.02000000, 0.00311769, 0.00333915), "weight": 1},
	{"id": "flashlight", "group": "F_flashlight", "glb_path": "res://assets/models/props/prop_desk_flashlight.glb", "size_m": Vector3(0.02400000, 0.02400000, 0.04800000), "weight": 1},
	{"id": "clip_lamp", "group": "F_far", "glb_path": "res://assets/models/props/prop_desk_clip_lamp.glb", "size_m": Vector3(0.03500000, 0.04700000, 0.03300000), "weight": 1},
	{"id": "handheld", "group": "F_local", "glb_path": "res://assets/models/props/prop_desk_handheld.glb", "size_m": Vector3(0.05500000, 0.01050000, 0.04000000), "weight": 1},
	{"id": "electronic_clock", "group": "F_local", "glb_path": "res://assets/models/props/prop_desk_electronic_clock.glb", "size_m": Vector3(0.04800000, 0.02300000, 0.02300000), "weight": 1},
	{"id": "mini_lamp", "group": "F_lamp", "glb_path": "res://assets/models/props/prop_desk_mini_lamp.glb", "size_m": Vector3(0.04756406, 0.07099999, 0.04756406), "weight": 1},
	{"id": "eraser", "group": "F_eraser", "glb_path": "res://assets/models/props/prop_desk_eraser.glb", "size_m": Vector3(0.09500000, 0.09500000, 0.09500000), "weight": 1},
	{"id": "folded_note", "group": "F_note", "glb_path": "res://assets/models/props/prop_desk_folded_note.glb", "size_m": Vector3(0.07000000, 0.00230000, 0.05000000), "weight": 1},
 ]
var _scenes := {}
func pick(group: String, rng: RandomNumberGenerator) -> Dictionary:
 var options := []
 var total := 0
 for item in ITEMS:
  if item.group == group:
   options.append(item)
   total += item.weight
 var ticket := rng.randi_range(0, total - 1)
 for item in options:
  ticket -= item.weight
  if ticket < 0:
   return item
 return options[0]
func item(id: String) -> Dictionary:
 for entry in ITEMS:
  if entry.id == id:
   return entry
 return {}
func instance(entry: Dictionary) -> Node3D:
 var result: Node3D
 if ResourceLoader.exists(entry.glb_path):
  if not _scenes.has(entry.id):
   _scenes[entry.id] = load(entry.glb_path)
  result = _scenes[entry.id].instantiate()
 else:
  result = Node3D.new()
  var mi := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = entry.size_m
  mi.mesh = mesh
  mi.position.y = entry.size_m.y / 2
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(0.65, 0.39, 0.19)
  mi.material_override = mat
  result.add_child(mi)
  result.set_meta("placeholder", true)
 result.set_meta("kit_id", entry.id)
 return result
