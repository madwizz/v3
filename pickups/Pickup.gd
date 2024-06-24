extends Area

class_name Pickup

enum PICKUP_TYPES { PISTOL, PISTOL_AMMO, SHOTGUN, SHOTGUN_AMMO, HEALTH }

export(PICKUP_TYPES) var pickup_type
export var ammo = 10
