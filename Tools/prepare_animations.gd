extends SceneTree
const CLIPS=["LightIdle","LightWalking","Sprint","Guarding","Slash1","HeavySpin","Jump","Roll","Hurt1","Die1","UsePotion","TPose"]
func _initialize():
	var source=load("res://Assets/Animations/MeleeLib.res") as AnimationLibrary
	if source==null:quit(1);return
	var subset=AnimationLibrary.new()
	for clip in CLIPS:subset.add_animation(clip,source.get_animation(clip))
	var result=ResourceSaver.save(subset,"res://Assets/Animations/DemoMelee.res")
	print("Prepared 12 demonstration clips: ",result)
	quit(result)
