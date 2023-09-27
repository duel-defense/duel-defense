extends Node2D

class_name Trail

@export var max_points = 5
@export var width = 1.0

var points = []
var process_count = 0

func _physics_process(delta):
	if process_count >= 3:
		if points.size() > max_points:
			points.pop_back()
		points.push_front(global_position)
		process_count = 0
			
	process_count += 1
	queue_redraw()

func _draw():
	if points.size() < 2:
		return
	
	var final_points = PackedVector2Array()
	var colors = PackedColorArray()
	var length = float(points.size())
	
	for i in range(length):
		var color = modulate
		final_points.append(points[i] - global_position)
		color.a = lerp(1.0, 0.0, i / length)
		colors.append(color)
		
	draw_set_transform(Vector2(0, 0), -get_parent().rotation)
	draw_polyline_colors(final_points, colors, width, true)
