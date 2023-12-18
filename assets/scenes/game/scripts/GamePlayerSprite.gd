class_name GamePlayerSprite extends AnimatedSprite2D

var player_id: int = -1
var display_name: String
var doll_name: String = ""

var is_moving: bool = false
var popup_is_playing = false
var last_dir: int = 0

@onready var display_name_label = $DisplayName
@onready var attack_feedback = $AttackFeedback

@onready var hover_control: Control = $CustomTooltipControl

var queued_movement: Array = []

var MAX_MOVE_TWEEN_DURATION: float = 3.0
var current_move_tween_duration: float = 0.4

var attack_done_wait_tween_duration = 0.5
var attack_feedback_tween_duration = 0.9

var is_me: bool = false
var is_dead: bool = false

func _ready():
	pause()
	__prepare_animations()
	play("idle")
	display_name_label.text = display_name
	EventBus.player_sprite_moved.connect(__player_sprite_moved_handler)
	EventBus.player_sprite_ended_movement_chain.connect(__player_sprite_ended_movement_chain_handler)
	EventBus.player_sprite_attacked.connect(__player_sprite_attacked_handler)
	EventBus.player_sprite_popup_displayed.connect(__player_sprite_popup_displayed_handler)
	EventBus.turn_color_updated.connect(__turn_color_updated_handler)
	EventBus.tooltip_updated.connect(__tooltip_updated_handler)
	display_name_label.label_settings = LabelSettings.new()
	display_name_label.label_settings.font_size = 22
	display_name_label.label_settings.outline_size = 5
	display_name_label.label_settings.outline_color = Color.BLACK
	display_name_label.label_settings.font_color = Color.WHITE if is_me == true else Color.DARK_GRAY


func __prepare_animations():
	if doll_name == "":
		push_error("ERROR, no doll name supplied")
		return
	sprite_frames = SpriteFrames.new()
	__add_anim_from_spritesheet(doll_name, "idle")
	__add_anim_from_spritesheet(doll_name, "move")
	__add_anim_from_spritesheet(doll_name, "attack")
	__add_anim_from_spritesheet(doll_name, "die")
	sprite_frames.set_animation_loop("attack", false)
	sprite_frames.set_animation_loop("die", false)
	speed_scale = 1.0


func __turn_color_updated_handler(turn_of_player):
	if player_id == turn_of_player:
		display_name_label.label_settings.font_color = Color.RED
	else:
		display_name_label.label_settings.font_color = Color.WHITE if is_me == true else Color.DARK_GRAY


func __move_with_lerp(move_direction: int):
	play("move")
	is_moving = true
	EventBus.anim_is_being_played.emit(true)
	var step_2_offset = Global.Constant.Direction.STEP_TO_V2OFFSET
	var target_pos = global_position + Vector2((step_2_offset[move_direction] * 32))
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", target_pos, current_move_tween_duration)
	t.finished.connect(__on_move_done)
	if move_direction == 0:
		flip_h = true
	elif move_direction == 2:
		flip_h = false


func __on_move_done():
	is_moving = false
	EventBus.anim_is_being_played.emit(false)
	EventBus.player_sprite_move_finished.emit()


func set_mapgrid_pos(mapgrid_position: Vector2):
	global_position = Global.Util.global_coord_at(mapgrid_position)


func __player_sprite_moved_handler(pid: int, direction: int):
	if is_dead == true:
		return
	if player_id != pid:
		return
	if is_moving == true:
		return
	current_move_tween_duration = 0.2
	EventBus.camera_force_panned.emit(global_position, current_move_tween_duration)
	__move_with_lerp(direction)


func __player_sprite_ended_movement_chain_handler(pid: int):
	if is_dead == true:
		return
	if player_id != pid:
		return
	if is_moving == true:
		return
	is_moving = false
	play("idle")


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


func __player_sprite_attacked_handler(pid, _target_mapgrid):
	if is_dead == true:
		return
	if player_id != pid:
		return
	EventBus.anim_is_being_played.emit(true)
	EventBus.camera_force_panned.emit(global_position, 0.01)
	var global_target_pos = Global.Util.global_coord_at(_target_mapgrid)
	if global_target_pos.x > global_position.x:
		flip_h = false
	elif global_target_pos.x < global_position.x:
		flip_h = true
	animation_finished.connect(__player_sprite_attack_finished)
	play("attack")


func __player_sprite_attack_finished():
	animation_finished.disconnect(__player_sprite_attack_finished)
	EventBus.player_sprite_attack_finished.emit()
	var wait_tween = create_tween()
	wait_tween.tween_interval(attack_done_wait_tween_duration)
	wait_tween.finished.connect(__attack_wait_tween_finished)


func __attack_wait_tween_finished():
	play("idle")
	EventBus.anim_is_being_played.emit(false)


func __player_sprite_popup_displayed_handler(pid: int, message: String, message_color: Color, _is_dead: bool):
	if player_id != pid:
		return
	if popup_is_playing == true:
		return
	if is_dead == true:
		EventBus.player_sprite_popup_finished.emit()
		return
	EventBus.anim_is_being_played.emit(true)
	EventBus.camera_force_panned.emit(global_position, 0.01)
	attack_feedback.clear()
	attack_feedback.self_modulate = Color(1, 1, 1, 1)
	attack_feedback.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	attack_feedback.push_font_size(24)
	attack_feedback.push_outline_size(5)
	attack_feedback.push_bold()
	attack_feedback.push_color(message_color)
	attack_feedback.append_text(message)
	attack_feedback.pop()
	attack_feedback.pop()
	attack_feedback.pop()
	attack_feedback.pop()
	attack_feedback.pop()
	popup_is_playing = true
	var attack_feedback_tween = create_tween()
	attack_feedback_tween.tween_property(attack_feedback, "position", attack_feedback.position + Vector2(0, -75), attack_feedback_tween_duration)
	attack_feedback_tween.parallel()
	(attack_feedback_tween.tween_property(attack_feedback, "self_modulate", Color(1, 1, 1, 0), attack_feedback_tween_duration)
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART))
	attack_feedback_tween.finished.connect(__popup_tween_finished)
	if _is_dead == true:
		play("die")
	is_dead = _is_dead


func __popup_tween_finished():
	attack_feedback.position -= Vector2(0, -75)
	attack_feedback.clear()
	popup_is_playing = false
	EventBus.anim_is_being_played.emit(false)
	EventBus.player_sprite_popup_finished.emit()


func __tooltip_updated_handler(pid, _tooltip_text):
	if player_id != pid:
		return
	hover_control.tooltip_text = _tooltip_text
