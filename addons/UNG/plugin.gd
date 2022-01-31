tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("HumanID", "Node", preload("Identity/VerbalIDHuman.gd"), preload("ung_id.png"))


func _exit_tree():
	remove_custom_type("HumanID")
