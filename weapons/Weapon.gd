extends Spatial

# Considering the animation is done via the visible boolean in animation tracks
# All these changes are due to timer and previous 3D weapons
# All that should just work through AnimatedSprite3D node but it doesn't
# TODO ? rewrite it if anim_name.is_playing: idle_anim visible = false or similar

onready var anim_player = $Animations/AnimationPlayer
onready var bullet_emitters_base : Spatial = $BulletEmitters
onready var bullet_emitters = $BulletEmitters.get_children()

export var automatic = false

var fire_point : Spatial
var bodies_to_exclude : Array = []

export var damage = 5
export var ammo = 30
export var ammo_mag_max = 10
var ammo_mag = ammo_mag_max

export var attack_rate = 0.2
var attack_timer : Timer
var can_attack = true

signal fired
signal out_of_ammo

func _ready():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_rate
	attack_timer.connect("timeout", self, "finish_attack")
	attack_timer.one_shot = true
	add_child(attack_timer)
	
	# default idle all the time
	# surprisingly animation switch is smooth
	anim_player.play("idle")

func init(_fire_point: Spatial, _bodies_to_exclude: Array):
	fire_point = _fire_point
	bodies_to_exclude = _bodies_to_exclude
	for bullet_emitter in bullet_emitters:
		bullet_emitter.set_damage(damage)
		bullet_emitter.set_bodies_to_exclude(bodies_to_exclude)

func attack(attack_input_just_pressed: bool, attack_input_held: bool):
	if !can_attack:
		return
	if automatic and !attack_input_held:
		return
	elif !automatic and !attack_input_just_pressed:
		return
	
	if ammo_mag == 0:
		if attack_input_just_pressed:
			emit_signal("out_of_ammo")
			play_animation("empty")
		return
	
	if ammo_mag > 0:
		ammo_mag -= 1
	
	var start_transform = bullet_emitters_base.global_transform
	bullet_emitters_base.global_transform = fire_point.global_transform
	for bullet_emitter in bullet_emitters:
		bullet_emitter.fire()
	bullet_emitters_base.global_transform = start_transform
	
	play_animation("attack")
	emit_signal("fired")
	can_attack = false
	attack_timer.start()

func finish_attack():
	can_attack = true
	check_idle()

func reload():
	if ammo_mag < ammo_mag_max and ammo > 0:
		can_attack = false
		var ammo_needed = ammo_mag_max - ammo_mag
		var ammo_to_reload = min(ammo_needed, ammo)
		ammo_mag += ammo_to_reload
		ammo -= ammo_to_reload
		play_animation("reload")

func _on_reload_finished(anim_name):
	if anim_name == "reload" or anim_name == "empty":
		can_attack = true
		anim_player.disconnect("animation_finished", self, "_on_reload_finished")
		check_idle()

func play_animation(anim_name: String):
	if anim_player.is_playing():
		anim_player.stop()
	anim_player.play(anim_name)
	if anim_name == "reload" or anim_name == "empty":
		anim_player.connect("animation_finished", self, "_on_reload_finished")

func check_idle():
	if !anim_player.is_playing():
		anim_player.play("idle")

func set_active():
	show()
	$Crosshair.show()

func set_inactive():
	hide()
	$Crosshair.hide()
	check_idle()

func is_idle():
	return !anim_player.is_playing() or anim_player.current_animation == "idle"

# Optional: Function to check if the weapon needs reloading
func needs_reload() -> bool:
	return ammo_mag < ammo_mag_max and ammo > 0

# Bind the reload action
func _input(event):
	if event.is_action_pressed("reload"):
		reload()
