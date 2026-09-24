extends SceneTree
var failed=false
func check(ok:bool,message:String):
	print("PASS " if ok else "FAIL ",message)
	if not ok:failed=true
func _initialize():call_deferred("run")
func run():
	var scene=load("res://Scenes/atelier.tscn").instantiate();root.add_child(scene)
	await process_frame
	var c=scene.character
	check(c.skeleton.get_bone_count()==56,"56 imported bones")
	var profile=SkeletonProfileHumanoid.new()
	var mapping=load("res://Assets/Animations/Mixamo BoneMap.tres") as BoneMap
	var worst=0.0
	for i in profile.bone_size:
		var standard=profile.get_bone_name(i)
		var bone=mapping.get_skeleton_bone_name(standard)
		if bone.is_empty():bone=standard
		var j=c.skeleton.find_bone(bone)
		check(j>=0,"BoneMap "+str(standard))
		if j>=0:
			var q=c.skeleton.get_bone_rest(j).basis.get_rotation_quaternion()
			worst=max(worst,q.angle_to(profile.get_reference_pose(i).basis.get_rotation_quaternion()))
	check(worst<.001,"rest axes match Humanoid Profile; max radians="+str(worst))
	for clip in c.CLIPS:
		c.play_clip(clip)
		var a=c.player.get_animation("Melee/"+clip)
		var snapshots=[]
		for t in [.1,.45,.8]:
			c.player.seek(a.length*t,true)
			var pose=[]
			for j in c.skeleton.get_bone_count():
				var transform=c.skeleton.get_bone_global_pose(j)
				check(transform.origin.is_finite(),clip+" non-finite bone") if not transform.origin.is_finite() else false
				pose.append(transform)
			snapshots.append(pose)
		check(a.get_track_count()>40,"mapped tracks "+clip)
		check(clip in ["TPose","Guarding"] or snapshots[0]!=snapshots[1],"animated pose changes "+clip)
	scene.select_clip(2);scene.toggle_pause();var at=c.player.current_animation_position
	await create_timer(.1).timeout
	check(is_equal_approx(at,c.player.current_animation_position),"Pause holds animation time")
	scene.toggle_pause();await create_timer(.1).timeout
	check(c.player.current_animation_position>at,"Resume advances animation")
	scene.select_clip(9);c.player.seek(c.player.current_animation_length,true);scene.select_clip(9)
	check(c.player.current_animation_position<.1,"Replay resets completed action")
	print("VALIDATION_FAILED" if failed else "VALIDATION_OK")
	scene.queue_free();await process_frame;await process_frame;quit(1 if failed else 0)
