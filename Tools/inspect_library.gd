extends SceneTree
func _initialize():
	var lib = load("res://Assets/Animations/MeleeLib.res") as AnimationLibrary
	print("CLIPS ", lib.get_animation_list())
	var a = lib.get_animation("TPose")
	for i in range(a.get_track_count()):
		print(a.track_get_path(i), " type=", a.track_get_type(i), " first=", a.track_get_key_value(i,0))
	var p = SkeletonProfileHumanoid.new()
	var bones = []
	for i in p.bone_size:
		var t = p.get_reference_pose(i)
		bones.append({"name":p.get_bone_name(i), "parent":p.get_bone_parent(i),"origin":[t.origin.x,t.origin.y,t.origin.z],"basis":[[t.basis.x.x,t.basis.x.y,t.basis.x.z],[t.basis.y.x,t.basis.y.y,t.basis.y.z],[t.basis.z.x,t.basis.z.y,t.basis.z.z]]})
	var f=FileAccess.open("res://Tools/humanoid_profile.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(bones,"  "))
	quit()

