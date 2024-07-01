extends Sprite

var health_sprites = [
	preload("res://ui/face_sprites/0_hp.png"),
	preload("res://ui/face_sprites/15_hp.png"),
	preload("res://ui/face_sprites/40_hp.png"),
	preload("res://ui/face_sprites/75_hp.png"),
	preload("res://ui/face_sprites/100_hp.png")
]

onready var health_manager = $"../../HealthManager"

func _ready():
	health_manager.connect("health_changed", self, "_on_health_changed")
	_on_health_changed(health_manager.cur_health)

func _on_health_changed(health):
	if health > 75:
		texture = health_sprites[4]
	elif health > 40:
		texture = health_sprites[3]
	elif health > 15:
		texture = health_sprites[2]
	elif health > 0:
		texture = health_sprites[1]
	else:
		texture = health_sprites[0]

