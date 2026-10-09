extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _assert_true(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failed = true
		push_error("FAIL: " + message)

func _run() -> void:
	var packed = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	game._start_run()
	paused = false
	await process_frame

	_assert_true(game.room_counts.size() == 9, "nine combat rooms registered")
	_assert_true(is_instance_valid(game.player), "player spawned")
	_assert_true(is_instance_valid(game.boss), "boss spawned")

	for room_id in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		var group_name := "room_%d_enemies" % room_id
		var enemies := get_nodes_in_group(group_name)
		_assert_true(enemies.size() > 0, "room %d has enemies" % room_id)
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.take_damage(9999)
		await process_frame
		game._reconcile_room_gate(room_id)
		_assert_true(not game.gates.has(room_id), "room %d gate unlocks" % room_id)

	game.player.global_position = Vector2(14700, 600)
	game._process(0.016)
	await process_frame
	_assert_true(game.boss_started, "boss encounter activates")
	_assert_true(game.boss.active, "THE IDOL becomes active")

	game.boss.take_damage(99999)
	await process_frame
	_assert_true(game.level_finished, "boss death finishes the level")

	if failed:
		print("SMOKE_RESULT: FAIL")
		quit(1)
	else:
		print("SMOKE_RESULT: PASS")
		quit(0)
