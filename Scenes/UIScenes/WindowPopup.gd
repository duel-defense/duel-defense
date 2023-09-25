extends Window

class_name WindowPopup

@export var content_container: Node

func _unhandled_input(event):
	if event.is_action_released("ui_cancel") or event.is_action_released("ui_menu"):
		self.visible = false

func open_popup():
	self.popup_centered()
	var container = content_container
	if not container:
		return
	var container_children = container.get_children()
	for child in container_children:
		if child is Label:
			continue
		child.grab_focus()
		break
	
func add_ui(node):
	add_to_scroll_container(node)

func add_to_scroll_container(node):
	content_container.add_child(node)

func clear_scroll_container():
	for child in content_container.get_children():
		child.queue_free()

func signal_config_updated(key):
	GameData.update_config(key)
