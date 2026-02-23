extends Node3D
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer

func _ready():
	AnimPlayer.play("idle")
