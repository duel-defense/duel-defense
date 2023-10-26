extends Node

class_name Helpers

static func play_button_sound():
	SoundManager.play_ui_sound(load("res://Assets/Audio/Sounds/click_003.ogg"))
	
static func play_error_sound():
	SoundManager.play_ui_sound(load("res://Assets/Audio/Sounds/error_007.ogg"))
	
static func play_confirm_sound():
	SoundManager.play_ui_sound(load("res://Assets/Audio/Sounds/confirmation_001.ogg"))

static func play_upgrade_sound():
	SoundManager.play_ui_sound(load("res://Assets/Audio/Sounds/confirmation_002.ogg"))
