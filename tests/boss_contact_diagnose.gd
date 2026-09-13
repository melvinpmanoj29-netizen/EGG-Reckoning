extends SceneTree

const BOSS_ROOM := preload("res://scenes/world/boss_room.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var room := BOSS_ROOM.instantiate()
	root.add_child(room)
	await physics_frame
	room.boss.current_phase = 3
	room.player.global_position = room.boss.global_position
	await physics_frame
	await physics_frame
	print("player_health=", room.player.health)
	for body in room.boss.hit_box.get_overlapping_bodies():
		print("overlap=", body.name, " player=", body.is_in_group("player"), " damage=", body.has_method("take_damage"))
	room.boss._physics_process(0.016)
	print("after_manual_health=", room.player.health)
	quit(0)
