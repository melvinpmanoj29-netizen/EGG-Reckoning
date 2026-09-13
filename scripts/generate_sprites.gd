extends SceneTree

## Procedural High-Quality 2D Sprite Generator for EGG: RECKONING
## Generates 100% solid opaque top-down sprites for Player, Enemies, and Boss.

func _init() -> void:
	print("--- GENERATING HIGH-QUALITY 2D GAME ASSETS ---")
	_generate_boy_sprite()
	_generate_girl_sprite()
	_generate_crawling_egg_sprite()
	_generate_poison_egg_sprite()
	_generate_demon_minion_sprite()
	_generate_boss_sprite()
	_generate_poison_projectile_sprite()
	_generate_egg_bomb_sprite()
	print("--- ALL 2D ASSETS GENERATED SUCCESSFULLY ---")
	quit(0)

func _set_pixel_aa(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= img.get_width() or y < 0 or y >= img.get_height():
		return
	if color.a <= 0.0:
		return
	var existing := img.get_pixel(x, y)
	if existing.a <= 0.0:
		img.set_pixel(x, y, color)
	else:
		var blended := existing.blend(color)
		blended.a = max(existing.a, color.a)
		img.set_pixel(x, y, blended)

func _draw_circle(img: Image, cx: float, cy: float, radius: float, fill_color: Color, outline_color: Color = Color.BLACK, outline_w: float = 2.0) -> void:
	var r_sq := radius * radius
	var out_sq := (radius + outline_w) * (radius + outline_w)
	var x_min := int(maxf(0.0, cx - radius - outline_w - 1.0))
	var x_max := int(minf(float(img.get_width() - 1), cx + radius + outline_w + 1.0))
	var y_min := int(maxf(0.0, cy - radius - outline_w - 1.0))
	var y_max := int(minf(float(img.get_height() - 1), cy + radius + outline_w + 1.0))

	for y in range(y_min, y_max + 1):
		for x in range(x_min, x_max + 1):
			var d_sq := (float(x) - cx) * (float(x) - cx) + (float(y) - cy) * (float(y) - cy)
			if d_sq <= r_sq:
				_set_pixel_aa(img, x, y, fill_color)
			elif d_sq <= out_sq:
				_set_pixel_aa(img, x, y, outline_color)

func _draw_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, angle: float, fill_color: Color, outline_color: Color = Color.BLACK, outline_w: float = 2.0) -> void:
	var cos_a := cos(-angle)
	var sin_a := sin(-angle)
	var max_r: float = maxf(rx, ry) + outline_w + 2.0
	var x_min := int(maxf(0.0, cx - max_r))
	var x_max := int(minf(float(img.get_width() - 1), cx + max_r))
	var y_min := int(maxf(0.0, cy - max_r))
	var y_max := int(minf(float(img.get_height() - 1), cy + max_r))

	for y in range(y_min, y_max + 1):
		for x in range(x_min, x_max + 1):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var local_x := dx * cos_a - dy * sin_a
			var local_y := dx * sin_a + dy * cos_a

			var norm := (local_x * local_x) / (rx * rx) + (local_y * local_y) / (ry * ry)
			var out_rx := rx + outline_w
			var out_ry := ry + outline_w
			var out_norm := (local_x * local_x) / (out_rx * out_rx) + (local_y * local_y) / (out_ry * out_ry)

			if norm <= 1.0:
				_set_pixel_aa(img, x, y, fill_color)
			elif out_norm <= 1.0:
				_set_pixel_aa(img, x, y, outline_color)

# ---------------------------------------------------------
# 1. BOY SURVIVOR / DETECTIVE (Top-down, 100% solid opaque)
# ---------------------------------------------------------
func _generate_boy_sprite() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Shoulders / Field Trench Coat (Dark Slate Blue)
	_draw_ellipse(img, 64, 64, 28, 38, 0.0, Color(0.18, 0.22, 0.28, 1.0), Color(0.08, 0.10, 0.14, 1.0), 3.0)
	
	# Coat Collar / Scarf (Deep Amber-Brown)
	_draw_ellipse(img, 64, 62, 16, 20, 0.0, Color(0.35, 0.22, 0.15, 1.0), Color(0.12, 0.08, 0.05, 1.0), 2.0)

	# Left & Right Hands (Reaching forward in top-down view)
	_draw_circle(img, 88, 48, 8.0, Color(0.85, 0.70, 0.58, 1.0), Color(0.12, 0.10, 0.08, 1.0), 2.0)
	_draw_circle(img, 88, 80, 8.0, Color(0.85, 0.70, 0.58, 1.0), Color(0.12, 0.10, 0.08, 1.0), 2.0)

	# Head (Skin tone)
	_draw_circle(img, 60, 64, 17.0, Color(0.88, 0.72, 0.60, 1.0), Color(0.12, 0.10, 0.08, 1.0), 2.5)

	# Hair (Short Dark Brown Textured)
	_draw_ellipse(img, 56, 64, 15, 16, 0.0, Color(0.24, 0.15, 0.10, 1.0), Color(0.10, 0.06, 0.04, 1.0), 2.0)
	_draw_circle(img, 52, 60, 9.0, Color(0.28, 0.18, 0.12, 1.0))
	_draw_circle(img, 52, 68, 9.0, Color(0.28, 0.18, 0.12, 1.0))

	img.save_png("res://assets/characters/boy/sprite.png")
	print("[SAVED] res://assets/characters/boy/sprite.png")

# ---------------------------------------------------------
# 2. GIRL SURVIVOR / DETECTIVE (Top-down, 100% solid opaque)
# ---------------------------------------------------------
func _generate_girl_sprite() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Shoulders / Leather Jacket (Warm Burgundy / Crimson-Brown)
	_draw_ellipse(img, 64, 64, 26, 36, 0.0, Color(0.32, 0.15, 0.18, 1.0), Color(0.12, 0.06, 0.08, 1.0), 3.0)

	# Scarf / Inner Shirt (Slate Grey)
	_draw_ellipse(img, 64, 62, 14, 18, 0.0, Color(0.25, 0.28, 0.32, 1.0), Color(0.10, 0.12, 0.15, 1.0), 2.0)

	# Hands
	_draw_circle(img, 86, 48, 7.5, Color(0.90, 0.74, 0.62, 1.0), Color(0.12, 0.10, 0.08, 1.0), 2.0)
	_draw_circle(img, 86, 80, 7.5, Color(0.90, 0.74, 0.62, 1.0), Color(0.12, 0.10, 0.08, 1.0), 2.0)

	# Head
	_draw_circle(img, 60, 64, 16.0, Color(0.90, 0.74, 0.62, 1.0), Color(0.12, 0.10, 0.08, 1.0), 2.5)

	# Hair (Auburn Ponytail / Waves)
	_draw_ellipse(img, 55, 64, 16, 17, 0.0, Color(0.48, 0.22, 0.12, 1.0), Color(0.16, 0.08, 0.04, 1.0), 2.0)
	_draw_circle(img, 42, 64, 10.0, Color(0.42, 0.18, 0.10, 1.0), Color(0.16, 0.08, 0.04, 1.0), 2.0) # Ponytail bun

	img.save_png("res://assets/characters/girl/sprite.png")
	print("[SAVED] res://assets/characters/girl/sprite.png")

# ---------------------------------------------------------
# 3. CRAWLING EGG MINION (Cracked egg, monstrous spider limbs)
# ---------------------------------------------------------
func _generate_crawling_egg_sprite() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Organic arachnid/insectoid legs (4 pairs)
	var leg_angles := [-1.2, -0.6, 0.6, 1.2, 2.0, 2.6, 3.8, 4.4]
	for a in leg_angles:
		var lx := 64.0 + cos(a) * 38.0
		var ly := 64.0 + sin(a) * 38.0
		_draw_ellipse(img, lx, ly, 14, 5, a, Color(0.18, 0.14, 0.12, 1.0), Color(0.06, 0.04, 0.02, 1.0), 2.0)
		# Leg joint claw
		var tip_x := lx + cos(a) * 16.0
		var tip_y := ly + sin(a) * 16.0
		_draw_circle(img, tip_x, tip_y, 3.5, Color(0.08, 0.06, 0.04, 1.0))

	# Main Calcified Egg Shell (Bone White with Putrid Undertone)
	_draw_ellipse(img, 64, 64, 32, 26, 0.0, Color(0.82, 0.80, 0.74, 1.0), Color(0.15, 0.12, 0.10, 1.0), 3.0)
	
	# Dark Fissures / Cracks
	_draw_ellipse(img, 68, 64, 18, 12, 0.3, Color(0.25, 0.18, 0.15, 1.0), Color(0.10, 0.06, 0.04, 1.0), 1.5)
	
	# Malevolent Glowing Red Eye Cluster
	_draw_circle(img, 76, 58, 4.5, Color(1.0, 0.15, 0.10, 1.0), Color(0.4, 0.0, 0.0, 1.0), 1.5)
	_draw_circle(img, 78, 68, 3.5, Color(1.0, 0.25, 0.10, 1.0), Color(0.4, 0.0, 0.0, 1.0), 1.5)
	_draw_circle(img, 70, 64, 2.5, Color(1.0, 0.8, 0.2, 1.0)) # Eye reflection core

	img.save_png("res://assets/enemies/crawling_egg/sprite.png")
	print("[SAVED] res://assets/enemies/crawling_egg/sprite.png")

# ---------------------------------------------------------
# 4. POISON EGG (Corrupted toxic pustules & dripping venom)
# ---------------------------------------------------------
func _generate_poison_egg_sprite() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Toxic bulbous pods
	_draw_circle(img, 42, 50, 14.0, Color(0.20, 0.45, 0.15, 1.0), Color(0.08, 0.18, 0.05, 1.0), 2.5)
	_draw_circle(img, 44, 78, 13.0, Color(0.18, 0.42, 0.14, 1.0), Color(0.08, 0.18, 0.05, 1.0), 2.5)
	_draw_circle(img, 82, 46, 12.0, Color(0.28, 0.55, 0.18, 1.0), Color(0.08, 0.18, 0.05, 1.0), 2.0)

	# Main Sickly Green-Tinted Egg Shell
	_draw_ellipse(img, 64, 64, 30, 26, 0.0, Color(0.48, 0.68, 0.35, 1.0), Color(0.10, 0.22, 0.08, 1.0), 3.0)

	# Corrupted Toxic Veins & Fissures
	_draw_ellipse(img, 66, 64, 16, 10, -0.2, Color(0.15, 0.32, 0.10, 1.0), Color(0.06, 0.14, 0.04, 1.0), 1.5)

	# Spitting Acid Maw / Eye
	_draw_ellipse(img, 78, 64, 7, 12, 0.0, Color(0.10, 0.28, 0.08, 1.0), Color(0.04, 0.12, 0.02, 1.0), 2.0)
	_draw_circle(img, 76, 64, 4.0, Color(0.40, 1.0, 0.20, 1.0)) # Acid glow core
	_draw_circle(img, 84, 64, 2.5, Color(0.80, 1.0, 0.40, 1.0)) # Venom drip

	img.save_png("res://assets/enemies/poison_egg/sprite.png")
	print("[SAVED] res://assets/enemies/poison_egg/sprite.png")

# ---------------------------------------------------------
# 5. DEMON EGG MINION (Obsidian shell, crimson horns & spikes)
# ---------------------------------------------------------
func _generate_demon_minion_sprite() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Calcified Horns / Spikes (Back and sides)
	_draw_ellipse(img, 36, 44, 14, 7, -0.6, Color(0.28, 0.08, 0.10, 1.0), Color(0.08, 0.02, 0.03, 1.0), 2.5)
	_draw_ellipse(img, 36, 84, 14, 7, 0.6, Color(0.28, 0.08, 0.10, 1.0), Color(0.08, 0.02, 0.03, 1.0), 2.5)
	_draw_ellipse(img, 28, 64, 12, 6, 0.0, Color(0.35, 0.06, 0.08, 1.0), Color(0.08, 0.02, 0.03, 1.0), 2.0)

	# Main Obsidian-Crimson Demonic Shell
	_draw_ellipse(img, 64, 64, 32, 28, 0.0, Color(0.22, 0.06, 0.09, 1.0), Color(0.06, 0.01, 0.02, 1.0), 3.5)

	# Molten Lava / Demon Blood Core Fissure
	_draw_ellipse(img, 66, 64, 18, 14, 0.0, Color(0.75, 0.12, 0.08, 1.0), Color(0.30, 0.04, 0.03, 1.0), 2.0)

	# Twin Piercing Demonic Eyes
	_draw_ellipse(img, 76, 56, 6, 4, 0.3, Color(1.0, 0.35, 0.05, 1.0), Color(0.45, 0.05, 0.0, 1.0), 1.5)
	_draw_ellipse(img, 76, 72, 6, 4, -0.3, Color(1.0, 0.35, 0.05, 1.0), Color(0.45, 0.05, 0.0, 1.0), 1.5)
	_draw_circle(img, 77, 56, 2.0, Color(1.0, 0.9, 0.3, 1.0))
	_draw_circle(img, 77, 72, 2.0, Color(1.0, 0.9, 0.3, 1.0))

	img.save_png("res://assets/enemies/demon_egg/sprite.png")
	print("[SAVED] res://assets/enemies/demon_egg/sprite.png")

# ---------------------------------------------------------
# 6. DEMON EGG BOSS (Monolithic Specimen Zero with Crown of Thorns)
# ---------------------------------------------------------
func _generate_boss_sprite() -> void:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Massive Outer Crown of Calcified Horns
	var horn_angles := [-1.4, -0.9, -0.4, 0.4, 0.9, 1.4, 2.2, 2.8, 3.4, 4.0]
	for a in horn_angles:
		var hx := 128.0 + cos(a) * 82.0
		var hy := 128.0 + sin(a) * 82.0
		_draw_ellipse(img, hx, hy, 28, 12, a, Color(0.32, 0.08, 0.12, 1.0), Color(0.08, 0.01, 0.02, 1.0), 4.0)
		_draw_circle(img, hx + cos(a) * 22.0, hy + sin(a) * 22.0, 6.0, Color(0.55, 0.12, 0.15, 1.0), Color(0.1, 0, 0, 1), 2.0)

	# Heavy Obsidian Base Shell
	_draw_ellipse(img, 128, 128, 76, 68, 0.0, Color(0.18, 0.04, 0.06, 1.0), Color(0.04, 0.01, 0.01, 1.0), 5.0)

	# Deep Molten Fissures / Ruptured Shell Plates
	_draw_ellipse(img, 128, 128, 48, 42, 0.2, Color(0.58, 0.08, 0.05, 1.0), Color(0.20, 0.02, 0.02, 1.0), 3.0)
	_draw_ellipse(img, 134, 128, 30, 26, -0.15, Color(0.88, 0.18, 0.08, 1.0), Color(0.35, 0.05, 0.02, 1.0), 2.5)

	# Pulsating Occult Core
	_draw_circle(img, 138, 128, 18.0, Color(1.0, 0.45, 0.10, 1.0), Color(0.5, 0.08, 0.02, 1.0), 2.5)
	_draw_circle(img, 140, 128, 10.0, Color(1.0, 0.85, 0.35, 1.0))

	# Giant Demonic Slit Eyes
	_draw_ellipse(img, 154, 106, 14, 7, 0.4, Color(1.0, 0.25, 0.05, 1.0), Color(0.4, 0.02, 0.0, 1.0), 2.0)
	_draw_ellipse(img, 154, 150, 14, 7, -0.4, Color(1.0, 0.25, 0.05, 1.0), Color(0.4, 0.02, 0.0, 1.0), 2.0)
	_draw_circle(img, 156, 106, 4.0, Color(1.0, 0.95, 0.6, 1.0))
	_draw_circle(img, 156, 150, 4.0, Color(1.0, 0.95, 0.6, 1.0))

	img.save_png("res://assets/enemies/boss/boss_base.png")
	print("[SAVED] res://assets/enemies/boss/boss_base.png")

# ---------------------------------------------------------
# 7. PROJECTILES (Poison Spit & Boss Egg Bomb)
# ---------------------------------------------------------
func _generate_poison_projectile_sprite() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_circle(img, 32, 32, 16.0, Color(0.25, 0.85, 0.15, 0.9), Color(0.08, 0.35, 0.05, 1.0), 3.0)
	_draw_circle(img, 30, 30, 9.0, Color(0.70, 1.0, 0.35, 1.0))
	img.save_png("res://assets/effects/particles/toxic_particle.png")
	print("[SAVED] res://assets/effects/particles/toxic_particle.png")

func _generate_egg_bomb_sprite() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_ellipse(img, 32, 32, 18, 14, 0.0, Color(0.35, 0.05, 0.08, 1.0), Color(0.08, 0.01, 0.02, 1.0), 3.0)
	_draw_circle(img, 34, 32, 7.0, Color(1.0, 0.3, 0.05, 1.0))
	_draw_circle(img, 35, 32, 3.5, Color(1.0, 0.8, 0.2, 1.0))
	img.save_png("res://assets/enemies/boss/egg_bomb.png")
	print("[SAVED] res://assets/enemies/boss/egg_bomb.png")
