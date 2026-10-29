extends CharacterBody3D
@export var move_speed := 7.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.0025
var gravity: float = 18.0
var health := 100
var shot_cooldown := 0.0
var camera: Camera3D
var game

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var pivot = Node3D.new()
	pivot.position = Vector3(0, 1.55, 0)
	add_child(pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.25, 4.5)
	camera.rotation.x = deg_to_rad(-8)
	pivot.add_child(camera)
	camera.current = true
	var body_mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.7
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.85
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.65, 0.95)
	body_mesh.material_override = mat
	add_child(body_mesh)
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.7
	col.shape = shape
	col.position.y = 0.85
	add_child(col)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-65), deg_to_rad(35))
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			shoot()

func _physics_process(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 5 * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * 5 * delta)
	move_and_slide()

func shoot() -> void:
	if shot_cooldown > 0.0:
		return
	shot_cooldown = 0.25
	var from = camera.global_position
	var query = PhysicsRayQueryParameters3D.create(from, from + -camera.global_transform.basis.z * 60.0)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(1)
	if game:
		game.flash_crosshair()

func take_hit(amount: int) -> void:
	if game:
		game.damage_player(amount)
