extends CharacterBody3D
var target: Node3D
var hp := 3
var attack_timer := 0.0
var speed := 2.2
var gravity := 18.0

func _ready() -> void:
	var mesh = MeshInstance3D.new()
	var body = BoxMesh.new()
	body.size = Vector3(1.1,1.8,0.8)
	mesh.mesh = body
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.72,0.12,0.16)
	mat.metallic = 0.35
	mat.emission_enabled = true
	mat.emission = Color(0.3,0.015,0.02)
	mesh.material_override = mat
	mesh.position.y = 0.9
	add_child(mesh)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.1,1.8,0.8)
	col.shape = shape
	col.position.y = 0.9
	add_child(col)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	attack_timer = maxf(0.0,attack_timer-delta)
	if not is_on_floor(): velocity.y -= gravity*delta
	var offset = target.global_position-global_position
	var flat = Vector3(offset.x,0,offset.z)
	if flat.length() > 1.6:
		var dir = flat.normalized()
		velocity.x = dir.x*speed
		velocity.z = dir.z*speed
		look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x,0,8*delta)
		velocity.z = move_toward(velocity.z,0,8*delta)
		if attack_timer <= 0:
			attack_timer = 1.2
			if target.has_method("take_hit"): target.take_hit(10)
	move_and_slide()

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		if get_parent().has_method("enemy_defeated"):
			get_parent().enemy_defeated()
		queue_free()
