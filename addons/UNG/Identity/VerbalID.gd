class_name VerbalID
extends Node

var common_name: String setget set_common_name, get_common_name
var animate: bool setget set_animate, get_animate
var gendered: bool setget set_gendered, get_gendered
var gender_value: float setget set_gender_value, get_gender_value

var _root_name: String = "thing"
var _animated: bool = false


func _init() -> void:
	gendered = false
	gender_value = -1.0

func set_common_name(new_name) -> void:
	_root_name = new_name

func get_common_name() -> String:
	return _root_name

func set_animate(b) -> void:
	_animated = b

func get_animate() -> bool:
	return _animated

func set_gendered(b) -> void:
	gendered = b

func get_gendered() -> bool:
	return gendered

func set_gender_value(v) -> void:
	gendered = true
	gender_value = v

func get_gender_value() -> float:
	return gender_value

func get_gender() -> String:
	if gendered:
		return Identity.gender_value_to_label(gender_value)
	else:
		return "it"
