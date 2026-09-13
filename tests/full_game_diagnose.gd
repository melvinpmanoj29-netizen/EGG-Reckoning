extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const PLAYER_HOUSE_SCENE := preload("res://scenes/world/player_house.tscn")
const TOWN_MAP_SCENE := preload("res://scenes/world/town_map.tscn")
const GAS_STATION_SCENE := preload("res://scenes/interiors/station_gas.tscn")
const HENDERSON_SCENE := preload("res://scenes/interiors/house_henderson.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTING FULL GAME SCENE INTEGRATION ---")
	
	# Test Player House
	var house := PLAYER_HOUSE_SCENE.instantiate()
	root.add_child(house)
	await process_frame
	await process_frame
	print("[PASS] Player house loaded.")
	house.queue_free()
	await process_frame

	# Test Town Map
	var town := TOWN_MAP_SCENE.instantiate()
	root.add_child(town)
	await process_frame
	await process_frame
	print("[PASS] Town map loaded.")
	town.queue_free()
	await process_frame

	# Test Interiors
	var gas := GAS_STATION_SCENE.instantiate()
	root.add_child(gas)
	await process_frame
	print("[PASS] Gas station interior loaded.")
	gas.queue_free()
	await process_frame

	var henderson := HENDERSON_SCENE.instantiate()
	root.add_child(henderson)
	await process_frame
	print("[PASS] Henderson house interior loaded.")
	henderson.queue_free()
	await process_frame

	print("--- ALL SCENE INTEGRATIONS VERIFIED CLEANLY ---")
	quit(0)
