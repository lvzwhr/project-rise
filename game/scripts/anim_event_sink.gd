class_name AnimEventSink
extends Node3D

## Catches artist AnimationPlayer method tracks (path ../..) so they do not
## double-fire with the frame-counter events on the combat actor.

func hit_on() -> void:
	pass

func hit_off() -> void:
	pass

func iframe_on() -> void:
	pass

func iframe_off() -> void:
	pass

func hyperarmor_on() -> void:
	pass

func hyperarmor_off() -> void:
	pass

func can_buffer() -> void:
	pass
