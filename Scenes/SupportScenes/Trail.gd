extends Node2D

class_name Trail

@export var max_points = 5
@export var width = 1.0

var points = []
var process_count = 0

func _physics_process(_delta):
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
	
	var colors = PackedColorArray()
	var final_points = PackedVector2Array()
	
	for i in range(points.size()):
		var color = modulate
		final_points.append(points[i] - global_position)
		color.a = lerp(1.0, 0.0, float(i) / float(points.size()))
		colors.append(color)
		
	draw_polyline_colors(final_points, colors, width, true)
	draw_set_transform(Vector2(0, 0), -get_parent().rotation)
