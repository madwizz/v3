extends Spatial


enum WEAPON_SLOTS { MELEE, PISTOL, SHOTGUN }
var slots_unlocked = {
	WEAPON_SLOTS.MELEE: true,
	WEAPON_SLOTS.PISTOL: false,
	WEAPON_SLOTS.SHOTGUN: false,
}

onready var anim_player = $AnimationPlayer
onready var weapons = $Weapons.get_children()
onready var alert_area_hearing = $AlertAreaHearing
onready var alert_area_los = $AlertAreaLos


var cur_slot = 0
var cur_weapon = null
var fire_point : Spatial
var bodies_to_exclude : Array = []

signal ammo_changed

func _ready():
	pass

func init(_fire_point: Spatial, _bodies_to_exclude: Array):
	fire_point = _fire_point
	bodies_to_exclude = _bodies_to_exclude
	for weapon in weapons:
		if weapon.has_method("init"):
			weapon.init(_fire_point, _bodies_to_exclude)
	
	weapons[WEAPON_SLOTS.PISTOL].connect("fired", self, "alert_nearby_enemies")
	weapons[WEAPON_SLOTS.SHOTGUN].connect("fired", self, "alert_nearby_enemies")
	
	for weapon in weapons:
		weapon.connect("fired", self, "emit_ammo_changed_signal")
	
	switch_to_weapon_slot(WEAPON_SLOTS.MELEE)

func attack(attack_input_just_pressed: bool, attack_input_held: bool):
	if cur_weapon.has_method("attack"):
		cur_weapon.attack(attack_input_just_pressed, attack_input_held)

func switch_to_next_weapon():
	cur_slot = (cur_slot + 1) % slots_unlocked.size()
	if !slots_unlocked[cur_slot]:
		switch_to_next_weapon()
	else:
		switch_to_weapon_slot(cur_slot)

func switch_to_last_weapon():
	cur_slot = posmod((cur_slot - 1), slots_unlocked.size())
	if !slots_unlocked[cur_slot]:
		switch_to_last_weapon()
	else:
		switch_to_weapon_slot(cur_slot)

func switch_to_weapon_slot(slot_ind: int):
	if slot_ind < 0 or slot_ind >= slots_unlocked.size():
		return
	if !slots_unlocked[slot_ind]:  # Corrected to check slot_ind
		return
	disable_all_weapons()
	cur_weapon = weapons[slot_ind]
	if cur_weapon.has_method("set_active"):
		cur_weapon.set_active()
	else:
		cur_weapon.show()
	emit_ammo_changed_signal()


func disable_all_weapons():
	for weapon in weapons:
		if weapon.has_method("set_inactive"):
			weapon.set_inactive()
		else:
			weapon.hide()

func update_animation(velocity: Vector3, grounded: bool):
	if cur_weapon.has_method("is_idle") and !cur_weapon.is_idle():
		anim_player.play("idle")
	if !grounded or velocity.length() < 15.0:
		anim_player.play("idle", 0.05)
	anim_player.play("moving")

func alert_nearby_enemies():
	var nearby_enemies = alert_area_los.get_overlapping_bodies()
	for nearby_enemy in nearby_enemies:
		if nearby_enemy.has_method("alert"):
			nearby_enemy.alert()
	nearby_enemies = alert_area_hearing.get_overlapping_bodies()
	for nearby_enemy in nearby_enemies:
		if nearby_enemy.has_method("alert"):
			nearby_enemy.alert(false)

func get_pickup(pickup_type, ammo):
	match pickup_type:
		Pickup.PICKUP_TYPES.PISTOL:
			if !slots_unlocked[WEAPON_SLOTS.PISTOL]:
				slots_unlocked[WEAPON_SLOTS.PISTOL] = true
				switch_to_weapon_slot(WEAPON_SLOTS.PISTOL)
			weapons[WEAPON_SLOTS.PISTOL].ammo += ammo
		Pickup.PICKUP_TYPES.SHOTGUN:
			if !slots_unlocked[WEAPON_SLOTS.SHOTGUN]:
				slots_unlocked[WEAPON_SLOTS.SHOTGUN] = true
				switch_to_weapon_slot(WEAPON_SLOTS.SHOTGUN)
			weapons[WEAPON_SLOTS.SHOTGUN].ammo += ammo
	emit_ammo_changed_signal()

func emit_ammo_changed_signal():
	emit_signal("ammo_changed", cur_weapon.ammo)
