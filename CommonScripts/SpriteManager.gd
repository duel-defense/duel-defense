extends Node

class_name SpriteManager

static func convert_sprite_sheet_to_sprite_frames(spritesheet_path, sprite_size, fps):
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")
	sprite_frames.add_animation("default")
	sprite_frames.set_animation_loop("default", false)
	sprite_frames.set_animation_speed("default", fps)
	var full_spritesheet : Texture = load(spritesheet_path)
	var texture_size = full_spritesheet.get_size()
	var num_columns : int = int(texture_size.x/sprite_size.x)
	for x_coords in range(num_columns):
		for y_coords in range(int(texture_size.y/sprite_size.y)):
			var frame_tex := AtlasTexture.new()
			frame_tex.atlas = full_spritesheet
			frame_tex.region = Rect2(Vector2(x_coords,y_coords)*sprite_size,sprite_size)
			sprite_frames.add_frame("default",frame_tex,y_coords*num_columns+x_coords)
	return sprite_frames
