extends Area3D

@export var teleport:Node3D

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		#get_tree().reload_current_scene()		
		get_tree().change_scene_to_file("res://level_1.tscn")
		#body.transform = teleport.transform 
