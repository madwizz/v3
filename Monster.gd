extends KinematicBody

onready var char_mover = $CharacterMover
onready var anim_player = $Graphics/ghost/AnimationPlayer
onready var health_manager = $HealthManager
# in this scene node doesnt have a parent, but in world scene does
onready var nav : Navigation = get_parent()

enum STATES { IDLE, CHASE, ATTACK, DEAD }
var cur_state = STATES.IDLE

var player = null
var path = []

export var sight_angle = 45.0
export var turn_speed = 360.0

export var attack_range = 2.0
export var attack_rate = 0.5
var attack_timer : Timer
var can_attack = true

# custom speed for animation player
export var attack_speed = 1.0

signal attack

func _ready():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_rate
	attack_timer.connect("timeout", self, "finish_attack")
	attack_timer.one_shot = true
	add_child(attack_timer)
	
	player = get_tree().get_nodes_in_group("player")[0]
	var hitbox = $CollisionShape/HitBox
	if hitbox is HitBox:
		hitbox.connect("hurt", self, "hurt")
	set_state_idle()
	
	health_manager.connect("dead", self, "set_state_dead")
	char_mover.init(self)
	set_state_idle()

func _process(delta):
	match cur_state:
		STATES.IDLE:
			process_state_idle(delta)
		STATES.CHASE:
			process_state_chase(delta)
		STATES.ATTACK:
			process_state_attack(delta)
		STATES.DEAD:
			process_state_dead(delta)

func set_state_idle():
	cur_state = STATES.IDLE
	anim_player.play("Idle")

func set_state_chase():
	cur_state = STATES.CHASE
	anim_player.play("flying animation", 0.2)

func set_state_attack():
	cur_state = STATES.ATTACK

func set_state_dead():
	cur_state = STATES.DEAD
	anim_player.play("dying animation")
	char_mover.freeze()
	$CollisionShape.disabled = true

func process_state_idle(delta):
	if can_see_player():
		set_state_chase()

func process_state_chase(delta):
	if within_dop(attack_range) and has_los_player():
		set_state_attack()
	var player_pos = player.global_transform.origin
	var our_pos = global_transform.origin
	path = nav.get_simple_path(our_pos, player_pos)
	var goal_pos = player_pos
	if path.size() > 1:
		goal_pos = path[1]
	var dir = goal_pos - our_pos
	dir.y = 0
	char_mover.set_move_vec(dir)
	face_dir(dir, delta)

func process_state_attack(delta):
	char_mover.set_move_vec(Vector3.ZERO)
	# comment out line below to allow dodge the attacks
	# face_dir(global_transform.origin.direction_to(player.global_transform.origin), delta)
	if can_attack:
		if !within_dop(attack_range) or !can_see_player():
			set_state_chase()
		else:
			start_attack()

func process_state_dead(delta):
	pass

func hurt(dmg: int, dir: Vector3):
	# might be redundant but just in case
	if cur_state == STATES.IDLE:
		set_state_chase()
	health_manager.hurt(dmg, dir)

func start_attack():
	can_attack = false
	anim_player.play("ghost_attack", -1, attack_speed)
	attack_timer.start()

func emit_attack_signal():
	emit_signal("attack")

func finish_attack():
	can_attack = true

func can_see_player():
	var dir_to_player = global_transform.origin.direction_to(player.global_transform.origin)
	var forwards = global_transform.basis.z
	return rad2deg(forwards.angle_to(dir_to_player)) < sight_angle and has_los_player()

#los = line of sight
func has_los_player():
	# + Vector3.UP to shoot up the ground not onto it 1 unit up precisely
	var our_pos = global_transform.origin + Vector3.UP
	var player_pos = player.global_transform.origin + Vector3.UP
	var space_state = get_world().get_direct_space_state()\
	# 1 for the env layer
	var result = space_state.intersect_ray(our_pos, player_pos, [], 1)
	if result:
		return false
	return true

func face_dir(dir: Vector3, delta):
	var angle_diff = global_transform.basis.z.angle_to(dir)
	var turn_right = sign(global_transform.basis.x.dot(dir))
	if abs(angle_diff) < deg2rad(turn_speed) * delta:
		rotation.y = atan2(dir.x, dir.z)
	else:
		rotation.y += deg2rad(turn_speed) * delta * turn_right

func alert(check_los=true):
	if cur_state != STATES.IDLE:
		return
	if check_los and has_los_player():
		return
	anim_player.play("idle to flying")
	set_state_chase()

# dop = distance of the player
func within_dop(dis: float):
	return global_transform.origin.distance_to(player.global_transform.origin) < attack_range
