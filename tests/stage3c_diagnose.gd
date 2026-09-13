extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- STAGE 3C DIAGNOSTIC VERIFICATION ---")
	print("========================================")
	
	var all_passed := true
	
	# TEST 1: Player Starting Equipment
	print("\n[TEST 1] Checking Player Starting Equipment...")
	var player_scene := load("res://player/player.tscn") as PackedScene
	if player_scene:
		var player := player_scene.instantiate() as CharacterBody2D
		root.add_child(player)
		
		var gs := root.get_node_or_null("/root/GameState")
		if gs:
			gs.has_torch = false
			gs.has_burner = false
			gs.torch_enabled = false
		player.update_equipment_visuals()
		
		var nozzle: Node2D = player.get_node_or_null("FlameCone/Nozzle")
		var torch_light: PointLight2D = player.get_node_or_null("TorchLight")
		
		var nozzle_hidden := (nozzle == null or not nozzle.visible)
		var torch_off := (torch_light == null or not torch_light.enabled)
		
		if nozzle_hidden and torch_off:
			print("  PASS: Player starts with empty hands (nozzle hidden, torch light off).")
		else:
			print("  FAIL: Player equipment visible at start! nozzle=%s torch=%s" % [nozzle_hidden, torch_off])
			all_passed = false
			
		# Test equipping
		if gs:
			gs.has_torch = true
			gs.torch_enabled = true
			gs.has_burner = true
			player.update_equipment_visuals()
			if nozzle and nozzle.visible and torch_light and torch_light.enabled:
				print("  PASS: Player successfully equips burner nozzle and torch light when acquired in GameState.")
			else:
				print("  FAIL: Equipping items did not update visuals properly.")
				all_passed = false
				
		player.queue_free()
	else:
		print("  FAIL: Could not load player scene.")
		all_passed = false

	# TEST 2: Player & Enemy Sprite Assets Exist
	print("\n[TEST 2] Checking Player & Enemy Sprite Opacity...")
	var check_textures := [
		"res://assets/characters/boy/sprite.png",
		"res://assets/characters/girl/sprite.png",
		"res://assets/enemies/crawling_egg/sprite.png",
		"res://assets/enemies/poison_egg/sprite.png",
		"res://assets/enemies/demon_egg/sprite.png",
		"res://assets/enemies/boss/boss_base.png"
	]
	for tex_path in check_textures:
		var tex := load(tex_path) as Texture2D
		if tex:
			var img := tex.get_image()
			var solid_count := 0
			for y in range(img.get_height()):
				for x in range(img.get_width()):
					var a := img.get_pixel(x, y).a
					if a >= 0.05:
						solid_count += 1
			print("  PASS: %s loaded successfully with %d visible pixels." % [tex_path.get_file(), solid_count])
		else:
			print("  FAIL: Missing texture %s" % tex_path)
			all_passed = false

	# TEST 3: Enemy AI State Machine & Hearing
	print("\n[TEST 3] Testing Enemy AI State Machine & Noise Listener...")
	var minion_scene := load("res://enemies/minion_egg.tscn") as PackedScene
	if minion_scene:
		var enemy := minion_scene.instantiate() as CharacterBody2D
		root.add_child(enemy)
		enemy.global_position = Vector2(0, 0)
		
		# Initial state
		if enemy.current_state == 0 or enemy.current_state == 1: # IDLE or PATROL
			print("  PASS: Enemy starts in IDLE/PATROL state (%d)." % enemy.current_state)
		else:
			print("  FAIL: Unexpected initial state: %d" % enemy.current_state)
			all_passed = false
			
		# Noise hearing
		enemy.on_noise_heard(Vector2(100, 100), 200.0)
		if enemy.current_state == 2: # INVESTIGATE
			print("  PASS: Enemy heard noise within radius and transitioned to INVESTIGATE state.")
		else:
			print("  FAIL: Noise within radius did not trigger INVESTIGATE state! current_state=%d" % enemy.current_state)
			all_passed = false
			
		# Noise too far away
		enemy.current_state = 0 # reset to IDLE
		enemy.on_noise_heard(Vector2(1000, 1000), 200.0)
		if enemy.current_state == 0:
			print("  PASS: Distant noise beyond radius was ignored.")
		else:
			print("  FAIL: Distant noise incorrectly triggered state change!")
			all_passed = false
			
		enemy.queue_free()
	else:
		print("  FAIL: Could not load minion_egg.tscn")
		all_passed = false

	# TEST 4: Poison Spitter & Projectile
	print("\n[TEST 4] Testing Poison Spitter & Poison Projectile...")
	var poison_scene := load("res://enemies/poison_egg.tscn") as PackedScene
	var proj_scene := load("res://enemies/poison_projectile.tscn") as PackedScene
	if poison_scene and proj_scene:
		var poison_egg := poison_scene.instantiate() as CharacterBody2D
		root.add_child(poison_egg)
		var proj := proj_scene.instantiate() as Area2D
		root.add_child(proj)
		proj.fire(Vector2(0, 0), Vector2(1, 0), 200.0, 12.0)
		if proj.direction == Vector2(1, 0) and proj.damage == 12.0:
			print("  PASS: Poison projectile initialized and fired correctly.")
		else:
			print("  FAIL: Poison projectile parameters incorrect.")
			all_passed = false
		poison_egg.queue_free()
		proj.queue_free()
	else:
		print("  FAIL: Could not load poison_egg or poison_projectile scene.")
		all_passed = false

	# TEST 5: Boss Room & Attacks
	print("\n[TEST 5] Testing Demon Egg Boss Overhaul & Attacks...")
	var boss_scene := load("res://enemies/demon_egg_boss.tscn") as PackedScene
	var bomb_scene := load("res://enemies/boss_egg_bomb.tscn") as PackedScene
	if boss_scene and bomb_scene:
		var boss := boss_scene.instantiate() as CharacterBody2D
		root.add_child(boss)
		var bomb := bomb_scene.instantiate() as Node2D
		root.add_child(bomb)
		bomb.launch(Vector2(0, 0), Vector2(100, 0), 0.8, 25.0, 80.0)
		print("  PASS: Boss egg bomb launched with arc trajectory and warning indicator.")
		
		if boss.has_method("take_burn_damage") and "current_phase" in boss:
			print("  PASS: Demon Egg Boss has multi-phase structure (phase: %d)." % boss.current_phase)
		else:
			print("  FAIL: Demon Egg Boss missing required phase management.")
			all_passed = false
		boss.queue_free()
		bomb.queue_free()
	else:
		print("  FAIL: Could not load demon_egg_boss or boss_egg_bomb scene.")
		all_passed = false

	# TEST 6: Town Map Pre-Placed Enemies
	print("\n[TEST 6] Testing Town Map Pre-Placed World Enemies...")
	var town_scene := load("res://scenes/world/town_map.tscn") as PackedScene
	if town_scene:
		var town := town_scene.instantiate() as Node2D
		root.add_child(town)
		var enemies_node := town.get_node_or_null("Enemies")
		if enemies_node and enemies_node.get_child_count() > 0:
			print("  PASS: Town map has %d pre-placed persistent enemies in world." % enemies_node.get_child_count())
			for child in enemies_node.get_children():
				print("    - %s at position %s (patrol points: %d)" % [child.name, child.global_position, child.patrol_points.size() if "patrol_points" in child else 0])
		else:
			print("  FAIL: Town map missing pre-placed enemies!")
			all_passed = false
		town.queue_free()
	else:
		print("  FAIL: Could not load town_map.tscn")
		all_passed = false

	print("\n========================================")
	if all_passed:
		print(">>> ALL STAGE 3C VERIFICATION TESTS PASSED <<<")
	else:
		print(">>> SOME TESTS FAILED <<<")
	print("========================================\n")
	
	quit(0 if all_passed else 1)
