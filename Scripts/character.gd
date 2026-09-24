extends Node3D
const CLIPS = ["LightIdle","LightWalking","Sprint","Guarding","Slash1","HeavySpin","Jump","Roll","Hurt1","Die1","UsePotion","TPose"]
var player: AnimationPlayer
var skeleton: Skeleton3D
func _ready():
	var model = preload("res://Assets/Character/ember.glb").instantiate()
	add_child(model)
	skeleton = model.get_node("EmberRig/Skeleton3D")
	player = model.get_node("AnimationPlayer")
	for library in player.get_animation_library_list(): player.remove_animation_library(library)
	var mapping = load("res://Assets/Animations/Mixamo BoneMap.tres") as BoneMap
	var source = load("res://Assets/Animations/DemoMelee.res") as AnimationLibrary
	var library = AnimationLibrary.new()
	for clip in CLIPS:
		var anim = source.get_animation(clip).duplicate(true) as Animation
		for i in range(anim.get_track_count()-1,-1,-1):
			var path = anim.track_get_path(i)
			var standard = str(path.get_subname(0))
			var bone = str(mapping.get_skeleton_bone_name(standard)) if mapping.profile.find_bone(standard) >= 0 else standard
			if bone.is_empty(): bone=standard
			if skeleton.find_bone(bone)<0:
				anim.remove_track(i)
				continue
			anim.track_set_path(i,NodePath("EmberRig/Skeleton3D:"+bone))
		anim.loop_mode=Animation.LOOP_LINEAR if clip in ["LightIdle","LightWalking","Sprint","Guarding","TPose"] else Animation.LOOP_NONE
		library.add_animation(clip,anim)
	player.add_animation_library("Melee",library)
	play_clip("LightIdle")
func play_clip(clip: String):
	# Restore all bones so unkeyed tracks never retain the previous action.
	player.stop()
	skeleton.reset_bone_poses()
	player.play("Melee/"+clip)
	player.advance(0)
