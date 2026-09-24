extends Node3D
const Character = preload("res://Scripts/character.gd")
const LABELS=["Idle stance","Walk","Sprint","Guard","Sword slash","Heavy spin","Jump","Dodge roll","Take a hit","Fall","Use potion","T-pose"]
const NOTES=["A moment of stillness. Ready for the next move.","A steady walking cycle, played in place.","A full-body sprint with alternating arm swing.","A defensive pose, ready to block.","A quick, single-handed attack.","A powerful turn through a complete attack.","A jump sequence with vertical hip motion.","A forward evasive roll.","A short reaction to an incoming strike.","A complete fall. Replay to stand up again.","A short item-use gesture.","The reference pose used to build and bind the rig."]
var character: Node3D
var camera: Camera3D
var title_label: Label
var note_label: Label
var time_label: Label
var pause_button: Button
var progress: HSlider
var buttons: Array[Button]=[]
var selected=0
var orbit=0.35
var elevation=0.17
var distance=6.0
var auto_turn=false
var paused=false
var dragging=false
var scrubbing=false
var accent=Color("8af2ca")
func _ready():
	stage()
	character=Node3D.new();character.set_script(Character);character.name="Ember";add_child(character);character.position.y=.10
	ui()
	select_clip(0)
func material(color: Color, metallic=0.0):
	var m=StandardMaterial3D.new();m.albedo_color=color;m.metallic=metallic;m.roughness=.65;return m
func mesh_node(mesh: Mesh,position_: Vector3,mat: Material):
	var n=MeshInstance3D.new();n.mesh=mesh;n.material_override=mat;n.position=position_;add_child(n);return n
func stage():
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("0b141d");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("aecad1");e.ambient_light_energy=.65;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=e;add_child(env)
	var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-45,-35,0);key.light_energy=1.1;key.shadow_enabled=true;add_child(key)
	var fill=OmniLight3D.new();fill.position=Vector3(-2,2,-2);fill.light_color=accent;fill.light_energy=.8;fill.omni_range=7;add_child(fill)
	var floor_=PlaneMesh.new();floor_.size=Vector2(200,200);mesh_node(floor_,Vector3(0,-.22,0),material(Color("030608")))
	var plinth=CylinderMesh.new();plinth.top_radius=1.6;plinth.bottom_radius=1.7;plinth.height=.18;plinth.radial_segments=64;mesh_node(plinth,Vector3(0,-.10,0),material(Color("24343e"),.45))
	var ring=TorusMesh.new();ring.inner_radius=1.52;ring.outer_radius=1.54;ring.rings=64;var glow=material(accent);glow.emission_enabled=true;glow.emission=accent;mesh_node(ring,Vector3(0,0,0),glow)
	for i in 32:
		var tick=BoxMesh.new();tick.size=Vector3(.014,.008,.075 if i%4==0 else .03);var a=i*TAU/32;var n=mesh_node(tick,Vector3(sin(a)*1.43,.002,cos(a)*1.43),material(Color("75898e")));n.rotation.y=a
	camera=Camera3D.new();camera.fov=38;add_child(camera);camera.current=true
func text(parent: Node,value: String,size: int,color=Color("e6eee9")):
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);parent.add_child(l);return l
func style(bg:Color,border:Color):
	var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(8);s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=7;s.content_margin_bottom=7;return s
func button(parent:Node,value:String,callback:Callable):
	var b=Button.new();b.text=value;b.custom_minimum_size.y=36;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_font_size_override("font_size",16)
	b.add_theme_stylebox_override("normal",style(Color("162630"),Color("2d424d")));b.add_theme_stylebox_override("hover",style(Color("29443f"),accent));b.add_theme_stylebox_override("pressed",style(Color("315b4b"),accent));b.pressed.connect(callback);parent.add_child(b);return b
func ui():
	var canvas=CanvasLayer.new();add_child(canvas);var root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(root)
	var eyebrow=text(root,"MOTION ATELIER    /    BLENDER × GODOT",14,accent);eyebrow.position=Vector2(32,24)
	var brand=text(root,"EMBER",58);brand.position=Vector2(28,47)
	var sub=text(root,"A small character. A full range of motion.",18,Color("a6b9bc"));sub.position=Vector2(32,119)
	var divider=ColorRect.new();divider.color=Color("2a404a");divider.position=Vector2(32,164);divider.size=Vector2(1216,1);root.add_child(divider)
	var menu=VBoxContainer.new();menu.position=Vector2(32,185);menu.size=Vector2(260,0);menu.add_theme_constant_override("separation",5);root.add_child(menu)
	text(menu,"01  /  MOTION LIBRARY",13,accent)
	for i in LABELS.size():buttons.append(button(menu,"%02d    %s"%[i+1,LABELS[i]],select_clip.bind(i)))
	var backdrop=Panel.new();backdrop.position=Vector2(328,608);backdrop.size=Vector2(880,158);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.add_theme_stylebox_override("panel",style(Color("0c1922f5"),Color("2d424d")));root.add_child(backdrop)
	var info=VBoxContainer.new();info.position=Vector2(342,622);info.size=Vector2(650,0);root.add_child(info)
	text(info,"NOW PLAYING",12,accent);title_label=text(info,"",30);note_label=text(info,"",16,Color("a6b9bc"))
	var controls=HBoxContainer.new();controls.add_theme_constant_override("separation",9);info.add_child(controls)
	pause_button=button(controls,"Pause",toggle_pause);button(controls,"Replay",func():select_clip(selected));button(controls,"Rotate",func():auto_turn=not auto_turn)
	var speed=OptionButton.new();for label in ["0.5× speed","1× speed","1.5× speed"]:speed.add_item(label)
	speed.select(1);speed.item_selected.connect(func(i):character.player.speed_scale=[.5,1.,1.5][i]);controls.add_child(speed)
	button(controls,"Reset view",func():orbit=.35;elevation=.17;distance=6.0;auto_turn=false)
	progress=HSlider.new();progress.custom_minimum_size=Vector2(470,20);progress.step=.001;progress.drag_started.connect(func():scrubbing=true);progress.drag_ended.connect(func(_changed):scrubbing=false);progress.value_changed.connect(func(v):if scrubbing:character.player.seek(v,true));info.add_child(progress)
	time_label=text(root,"",14,Color("a6b9bc"));time_label.position=Vector2(1025,708)
	var spec=text(root,"ORIGINAL LOW-POLY MODEL\n56-bone humanoid rig\n12 motions / Melee Library",14,Color("92a6ad"));spec.position=Vector2(982,197)
	var hint=text(root,"Drag the stage to orbit  ·  Scroll to zoom  ·  Space to pause",13,Color("81999f"));hint.position=Vector2(342,773)
func select_clip(index:int):
	selected=index;paused=false;character.play_clip(Character.CLIPS[index]);title_label.text=LABELS[index];note_label.text=NOTES[index];pause_button.text="Pause"
	for i in buttons.size():buttons[i].add_theme_color_override("font_color",accent if i==index else Color("c7d5d6"))
	progress.max_value=character.player.current_animation_length
func toggle_pause():
	paused=not paused
	if paused:character.player.pause()
	else:character.player.play()
	pause_button.text="Resume" if paused else "Pause"
func _process(delta):
	if auto_turn:orbit+=delta*.35
	var target=Vector3(-.53,.82,0)
	camera.position=Vector3(sin(orbit)*distance,1.4+elevation*distance,cos(orbit)*distance);camera.look_at(target)
	if not scrubbing:progress.set_value_no_signal(character.player.current_animation_position)
	time_label.text="%04.1f / %04.1f s"%[character.player.current_animation_position,character.player.current_animation_length]
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode==KEY_SPACE:toggle_pause()
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:distance=clamp(distance-.25,3.3,7)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:distance=clamp(distance+.25,3.3,7)
	if event is InputEventMouseMotion and dragging:orbit-=event.relative.x*.008;elevation=clamp(elevation+event.relative.y*.004,-.08,.7)
