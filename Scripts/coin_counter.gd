extends Label

func _process(_delta):
	text = "Coins: " + str(GameManager.coins)
