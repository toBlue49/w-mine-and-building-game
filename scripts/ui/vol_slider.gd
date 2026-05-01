extends HSlider

func set_volume_value(vol: float):
	value = db_to_linear(vol)

func get_volume_value() -> float:
	return linear_to_db(value)
