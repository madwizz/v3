extends Area

class_name HitBox

# set this for headshots later, checkbox in inspector
export var weak_spot = false
export var crit_dmg_multiplier = 2
signal hurt

func hurt(dmg: int, dir: Vector3):
	if weak_spot:
		emit_signal("hurt", dmg * crit_dmg_multiplier, dir)
	else:
		emit_signal("hurt", dmg, dir)
