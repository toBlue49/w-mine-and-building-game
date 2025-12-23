extends Node3D

var id_counter = 0

@rpc("any_peer", "call_local") #TODO: Fix Multiplayer multiple sounds
func play(sound: String, pos: Vector3 = Vector3(0,0,0), vol: float = 0.0, rng_pitch:int = 0, despawn: bool = true):
	var soundplayer = load("res://scenes/sound_player.tscn").instantiate()
	soundplayer.name = str(id_counter)
	self.add_child(soundplayer)
	
	get_node(str(id_counter)).play_sound(sound, rng_pitch, pos, vol, despawn)
	id_counter += 1
