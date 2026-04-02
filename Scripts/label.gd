extends Label

func _process(delta):
	text = "Coins: " + str(GameManager.coins)
