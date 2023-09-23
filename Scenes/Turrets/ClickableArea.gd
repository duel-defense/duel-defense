extends Area2D

func _on_ClickableArea_input_event(_viewport, event, _shape_idx):
	if(event.is_action_pressed("ui_accept")):
		self.get_parent().accept_clicked()
	elif(event.is_action_pressed("ui_cancel")):
		self.get_parent().cancel_clicked()
