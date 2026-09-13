extends SceneTree

func _init():
	var img_boy = Image.load_from_file("res://assets/characters/boy/sprite.png")
	var img_girl = Image.load_from_file("res://assets/characters/girl/sprite.png")
	print("boy size=", img_boy.get_size(), " format=", img_boy.get_format())
	print("girl size=", img_girl.get_size(), " format=", img_girl.get_format())
	var boy_min_a = 1.0
	var boy_max_a = 0.0
	for y in range(img_boy.get_height()):
		for x in range(img_boy.get_width()):
			var a = img_boy.get_pixel(x, y).a
			if a > 0.01:
				boy_min_a = min(boy_min_a, a)
				boy_max_a = max(boy_max_a, a)
	print("boy alpha range=[", boy_min_a, ", ", boy_max_a, "]")
	quit(0)
