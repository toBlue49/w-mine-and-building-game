extends AudioStreamPlayer3D

func play_sound(sound: String, rng_pitch:int = 0, pos: Vector3 = Vector3(0,0,0), vol: float = 0.0, despawn: bool = true):
	if despawn:
		connect("finished", remove)
	
	stream = load("res://sound/" + sound + ".ogg")
	pitch_scale = randf_range(1-rng_pitch, 1+rng_pitch)
	position = pos
	volume_db = vol
	
	play()
	
func remove():
	self.queue_free()
