extends Node3D
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var breaking_mesh: MeshInstance3D = $BreakingMesh


func _ready():
	AnimPlayer.play("idle")
	
func update_breaking_mesh_alpha(alpha: float):
	breaking_mesh.mesh.surface_get_material(0).albedo_color.a = alpha
	if is_equal_approx(alpha, 0):
		breaking_mesh.visible = false
	else:
		breaking_mesh.visible = true
