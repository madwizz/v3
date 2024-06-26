extends Label

var ammo = 0
var health = 0

func update_ammo(amount):
	ammo = amount
	update_display()

func update_health(amount):
	health = amount
	update_display() 

func update_display():
	text = "Health: " + str(health)
	var ammo_amount = str(ammo)
	if ammo < 0:
		ammo_amount = "inf"
	text += "\nAmmo: " + ammo_amount
