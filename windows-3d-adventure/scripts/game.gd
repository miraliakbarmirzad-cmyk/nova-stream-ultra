extends Node3D
const PlayerScript = preload("res://scripts/player.gd")
var player
var hud: Label
var message: Label
var health := 100
var crystals := 0
var enemies_left := 0
var game_over := false
var crosshair: Label

func _ready() -> void:
	setup_input()
	build_world()
	build_ui()
	spawn_player()
	for p in [Vector3(7,0,-9), Vector3(-8,0,-15), Vector3(3,0,-23)]:
		spawn_crystal(p)
	for p in [Vector3(0,0,-12), Vector3(9,0,-20), Vector3(-8,0,-26)]:
		spawn_enemy(p)
	update_hud()

func setup_input() -> void:
	var binds = {"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN],"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE]}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in binds[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)

func build_world() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42,0.5,0.68)
	environment.ambient_light_energy = 0.8
	env.environment = environment
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_energy = 1.2
	add_child(sun)
	make_box("Ground", Vector3(0,-0.5,-12), Vector3(42,1,60), Color(0.12,0.18,0.2), true)
	for x in [-20,20]:
		make_box("Boundary", Vector3(x,2,-12), Vector3(1,4,60), Color(0.12,0.28,0.32), true)
	for z in [-5,-13,-21,-29]:
		for x in [-12,-6,6,12]:
			if randf() > 0.3:
				make_box("Ancient Ruin", Vector3(x,1.0,z), Vector3(1.5,2.0,1.5), Color(0.24,0.3,0.32), true)
	for i in range(24):
		var rock = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = randf_range(0.12,0.4)
		mesh.height = mesh.radius*2
		rock.mesh = mesh
		rock.position = Vector3(randf_range(-18,18), -0.05, randf_range(-35,8))
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(0.18,0.22,0.24)
		rock.material_override = m
		add_child(rock)

func make_box(n: String, pos: Vector3, size: Vector3, color: Color, solid: bool) -> Node3D:
	var root = StaticBody3D.new() if solid else Node3D.new()
	root.name = n
	root.position = pos
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape
		root.add_child(col)
	add_child(root)
	return root

func spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Explorer"
	player.set_script(PlayerScript)
	player.game = self
	player.position = Vector3(0,0,4)
	add_child(player)

func spawn_crystal(pos: Vector3) -> void:
	var area = Area3D.new()
	area.position = pos + Vector3(0,1,0)
	area.name = "EnergyCrystal"
	var mesh = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.8,1.2,0.8)
	mesh.mesh = prism
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05,0.95,1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0,0.8,1.0)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	area.add_child(mesh)
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.2
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(func(body): if body == player: collect_crystal(area))
	add_child(area)

func collect_crystal(area: Area3D) -> void:
	if not is_instance_valid(area): return
	crystals += 1
	area.queue_free()
	show_message("Energy crystal recovered!")
	update_hud()
	if crystals >= 3:
		game_over = true
		show_message("MISSION COMPLETE! All crystals recovered. Press R to restart.")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func spawn_enemy(pos: Vector3) -> void:
	var enemy = CharacterBody3D.new()
	enemy.name = "Sentinel"
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.position = pos
	enemy.target = player
	add_child(enemy)
	enemies_left += 1

func enemy_defeated() -> void:
	enemies_left = maxi(0, enemies_left-1)
	update_hud()

func damage_player(amount: int) -> void:
	if game_over: return
	health = maxi(0,health-amount)
	update_hud()
	if health <= 0:
		game_over = true
		show_message("MISSION FAILED — Press R to try again.")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func update_hud() -> void:
	if is_instance_valid(hud):
		hud.text = "NOVA: LOST FRONTIER     HP %d     CRYSTALS %d/3     SENTINELS %d\nWASD Move • SPACE Jump • Mouse Aim • Left Click Fire • ESC Release Mouse • R Restart" % [health,crystals,enemies_left]

func build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(22,18)
	hud.add_theme_font_size_override("font_size",18)
	hud.add_theme_color_override("font_color",Color(0.78,0.97,1))
	layer.add_child(hud)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8,-18)
	crosshair.add_theme_font_size_override("font_size",28)
	crosshair.add_theme_color_override("font_color",Color(0.1,1,1))
	layer.add_child(crosshair)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message.position = Vector2(-330,-75)
	message.add_theme_font_size_override("font_size",22)
	message.add_theme_color_override("font_color",Color(1,0.8,0.2))
	layer.add_child(message)

func show_message(text: String) -> void:
	message.text = text

func flash_crosshair() -> void:
	if is_instance_valid(crosshair):
		crosshair.add_theme_color_override("font_color",Color(1,0.5,0.15))

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_R) and game_over:
		get_tree().reload_current_scene()
	if is_instance_valid(crosshair) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		crosshair.add_theme_color_override("font_color",Color(0.1,1,1))
