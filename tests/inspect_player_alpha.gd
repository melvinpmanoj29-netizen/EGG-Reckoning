extends SceneTree

func _init():
	var img_boy = Image.load_from_file("res://assets/characters/boy/sprite.png")
	var solid_pixels = 0
	var low_alpha_pixels = 0
	var mid_alpha_pixels = 0
	for y in range(img_boy.get_height()):
		for x in range(img_boy.get_width()):
			var p = img_boy.get_pixel(x, y)
			if p.a > 0.01:
				if p.a < 0.3:
					low_alpha_pixels += 1
				elif p.a < 0.9:
					mid_alpha_pixels += 1
				else:
					solid_pixels += 1
	print("solid=", solid_pixels, " mid=", mid_alpha_pixels, " low=", low_alpha_pixels)
	quit(0)
