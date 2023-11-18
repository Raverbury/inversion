class_name GamePlayerSprite extends AnimatedSprite2D

var player_id: int = -1
var display_name: String
var doll_name: String = ""

var is_moving: bool = false
var last_dir: int = 0

@onready var display_name_label = $DisplayName
@onready var attack_feedback = $AttackFeedback

var queued_movement: Array = []

var attack_done_wait_tween_duration = 0.5
var attack_feedback_tween_duration = 1.2

func _ready():
	pause()
	__prepare_animations()
	play("idle")
	display_name_label.text = display_name
	EventBus.player_moved.connect(__player_moved_handler)
	EventBus.player_attacked.connect(__player_attacked_handler)
	EventBus.player_was_attacked.connect(__player_was_attacked_handler)


func __prepare_animations():
	if doll_name == "":
		print("ERROR, no doll name supplied")
		return
	sprite_frames = SpriteFrames.new()
	__add_anim_from_spritesheet(doll_name, "idle")
	__add_anim_from_spritesheet(doll_name, "move")
	__add_anim_from_spritesheet(doll_name, "attack")
	__add_anim_from_spritesheet(doll_name, "die")
	sprite_frames.set_animation_loop("attack", false)
	sprite_frames.set_animation_loop("die", false)
	speed_scale = 1.0


# func _process(_delta):
	# __process_queued_movement()


func __process_queued_movement():
	if queued_movement.is_empty():
		play("idle")
		return
	if is_moving:
		return
	last_dir = queued_movement.pop_front()
	play("move")
	__move_with_lerp(last_dir)


func __move_with_lerp(move_direction: int):
	is_moving = true
	var step_2_offset = Global.Constant.Direction.STEP_TO_V2OFFSET
	var target_pos = global_position + Vector2((step_2_offset[move_direction] * 32))
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", target_pos, 0.4)
	t.finished.connect(__on_move_done)
	if move_direction == 0:
		flip_h = true
	elif move_direction == 2:
		flip_h = false

func __on_move_done():
	is_moving = false
	__process_queued_movement()


func set_mapgrid_pos(mapgrid_position: Vector2):
	global_position = Global.Util.center_global_pos_at(mapgrid_position)


func __player_moved_handler(pid: int, steps: Array):
	if player_id != pid:
		return
	if is_moving == true:
		return
	queued_movement.append_array(steps)
	__process_queued_movement()


func __add_anim_from_spritesheet(_doll_name: String, anim: String):
	var spritesheet_path = Global.Constant.Spritesheet.make_path(_doll_name, anim)
	sprite_frames.add_animation(anim)
	var texture: Texture2D = load(spritesheet_path) as Texture2D
	var number_of_frames: int = int(texture.get_width() / 64.0)
	for i in range(number_of_frames):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(0 + i * 64, 0, 64, 64)
		sprite_frames.add_frame(anim, atlas)
	sprite_frames.set_animation_speed(anim, 60)


func __player_attacked_handler(pid, _target_mapgrid):
	if player_id != pid:
		return
	var global_target_pos = Global.Util.center_global_pos_at(_target_mapgrid)
	if global_target_pos.x > global_position.x:
		flip_h = false
	elif global_target_pos.x < global_position.x:
		flip_h = true
	animation_finished.connect(__attack_anim_finished)
	play("attack")
	"[font_size=30][outline_size=11][center][b][color=red]-5[/color][/b][/center][/outline_size][/font_size]"


func __attack_anim_finished():
	animation_finished.disconnect(__attack_anim_finished)
	EventBus.attack_anim_finished.emit()
	var wait_tween = create_tween()
	wait_tween.tween_interval(attack_done_wait_tween_duration)
	wait_tween.finished.connect(__attack_wait_tween_finished)


func __attack_wait_tween_finished():
	play("idle")


func __player_was_attacked_handler(pid: int, hit: bool, damage_taken: int):
	if player_id != pid:
		return
	attack_feedback.clear()
	attack_feedback.self_modulate = Color(1, 1, 1, 1)
	attack_feedback.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	attack_feedback.push_font_size(24)
	attack_feedback.push_outline_size(5)
	attack_feedback.push_bold()
	if hit == false:
		attack_feedback.push_color(Color.BLACK)
		attack_feedback.append_text("MISSED")
		attack_feedback.pop()
	else:
		attack_feedback.push_color(Color.RED)
		attack_feedback.append_text("-%s" % damage_taken)
		attack_feedback.pop()
	attack_feedback.pop()
	attack_feedback.pop()
	attack_feedback.pop()
	attack_feedback.pop()
	var attack_feedback_tween = create_tween()
	attack_feedback_tween.tween_property(attack_feedback, "position", Vector2(-100, -75), attack_feedback_tween_duration)
	attack_feedback_tween.parallel()
	(attack_feedback_tween.tween_property(attack_feedback, "self_modulate", Color(1, 1, 1, 0), attack_feedback_tween_duration)
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART))
	attack_feedback_tween.finished.connect(__attack_feedback_tween_finished)


func __attack_feedback_tween_finished():
	attack_feedback.position = Vector2(-100, 0)
	attack_feedback.clear()
