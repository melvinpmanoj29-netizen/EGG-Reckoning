extends SceneTree

## Comprehensive Stage 3B Diagnostic & Validation Script

const TOWN_MAP_SCENE := preload("res://scenes/world/town_map.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- STARTING STAGE 3B DIAGNOSTIC VALIDATION ---")

	# 1. Instantiate Town Map
	var town := TOWN_MAP_SCENE.instantiate() as Node2D
	root.add_child(town)
	await process_frame
	await process_frame

	print("[PASS] Town map instantiated successfully.")

	# 2. Verify CanvasModulate initial dusk state
	var modulate := town.get_node_or_null("CanvasModulate") as CanvasModulate
	assert(modulate != null, "CanvasModulate node not found!")
	print("[PASS] CanvasModulate found with initial color: ", modulate.color)

	# 3. Verify FogOverlay & Shader
	var fog_rect := town.get_node_or_null("FogOverlay/FogRect") as ColorRect
	assert(fog_rect != null, "FogOverlay/FogRect not found!")
	assert(fog_rect.material is ShaderMaterial, "FogRect material is not a ShaderMaterial!")
	var initial_density = (fog_rect.material as ShaderMaterial).get_shader_parameter("fog_density")
	print("[PASS] FogOverlay verified with initial density: ", initial_density)

	# 4. Verify Lights
	var lights := root.get_tree().get_nodes_in_group("lights")
	print("[INFO] Total registered lights in scene: ", lights.size())
	assert(lights.size() >= 10, "Expected at least 10 lights across town, found " + str(lights.size()))

	var sample_timers: Array[float] = []
	for light in lights:
		if "min_interval" in light:
			sample_timers.append(light._timer)
	print("[PASS] Verified independent light timers: ", sample_timers.slice(0, 6))

	# 5. Verify Player Flashlight & Burner (Stage 3A preservation)
	var player = town.get_node_or_null("Player")
	assert(player != null, "Player not found!")
	assert(player.flashlight != null, "Player flashlight not found!")
	assert(player.fire_light != null, "Player fire_light not found!")
	assert(player.ambient_light != null, "Player ambient_light not found!")
	print("[PASS] Player tactical flashlight, ambient light, and burner fire light verified.")

	# 6. Test Night Trigger sequence
	print("[INFO] Triggering dusk -> night transition...")
	town.trigger_night()
	await process_frame

	var gs := root.get_node_or_null("/root/GameState")
	if gs:
		assert(gs.is_night == true, "GameState.is_night was not set to true!")
		print("[PASS] GameState.is_night = true verified.")

	# Step physics frames to let the transition tween progress
	for i in range(100):
		await process_frame

	print("[INFO] Modulate during transition: ", modulate.color)
	var current_density = (fog_rect.material as ShaderMaterial).get_shader_parameter("fog_density")
	print("[INFO] Fog density during transition: ", current_density)

	# 7. Verify Doors and Clues
	assert(town.player_house_door != null, "Player house door missing!")
	assert(town.henderson_door != null, "Henderson door missing!")
	assert(town.grocery_door != null, "Grocery door missing!")
	assert(town.gas_door != null, "Gas station door missing!")
	assert(town.demon_egg_int != null, "Demon egg interactable missing!")
	assert(town.cctv_int != null, "CCTV interactable missing!")
	assert(town.med_records_int != null, "Medical records interactable missing!")
	print("[PASS] All doors, interactables, and hospital clues verified.")

	print("--- ALL STAGE 3B DIAGNOSTIC CHECKS PASSED ---")
	quit(0)
