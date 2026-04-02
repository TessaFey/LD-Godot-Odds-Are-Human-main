extends Node

@export var coins: int = 0

func add_coin():
	coins += 1
	print("Coins:", coins)
