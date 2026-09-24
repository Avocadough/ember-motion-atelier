extends SceneTree
func _initialize():
	var model=load("res://Assets/Character/ember.glb").instantiate()
	root.add_child(model)
	model.print_tree_pretty()
	for s in model.find_children("*","Skeleton3D"):
		for i in range(s.get_bone_count()):
			if i < 12: print(s.get_bone_name(i)," ",s.get_bone_rest(i))
	model.free()
	quit()
