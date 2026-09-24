"""Create the original Ember character from Blender primitives. Run with Blender -b -P."""
import bpy, json, pathlib, re, math
from mathutils import Matrix, Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
profile=json.loads((ROOT/'Tools/humanoid_profile.json').read_text())
mapping=dict(re.findall(r'bone_map/(\w+) = &"([^"]*)"',(ROOT/'Assets/Animations/Mixamo BoneMap.tres').read_text()))
names={b['name']:mapping.get(b['name']) or b['name'] for b in profile}
C=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
world={}
for b in profile:
    m=Matrix(b['basis']).transposed().to_4x4(); m.translation=Vector(b['origin'])*4/3
    world[b['name']]=world.get(b['parent'],Matrix.Identity(4))@m
arm=bpy.data.armatures.new('Ember_Humanoid'); rig=bpy.data.objects.new('EmberRig',arm)
bpy.context.collection.objects.link(rig); bpy.context.view_layer.objects.active=rig; rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for b in profile:
    bone=arm.edit_bones.new(names[b['name']]); bone.head=(C@world[b['name']]).translation
    bone.tail=bone.head+Vector((0,0,.08)); bone.matrix=C@world[b['name']]; bone.length=.08
    if b['parent']: bone.parent=arm.edit_bones[names[b['parent']]]
bpy.ops.object.mode_set(mode='OBJECT'); rig.show_in_front=True
def mat(name,color,metal=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=.42
    return m
teal=mat('Petrol enamel',(.025,.28,.30),.45); amber=mat('Burnished copper',(.85,.30,.075),.55)
dark=mat('Graphite joints',(.032,.048,.065),.35); ivory=mat('Porcelain',(.77,.84,.79),.3)
glow=mat('Mint visor',(.25,.95,.68)); p=glow.node_tree.nodes.get('Principled BSDF'); p.inputs['Emission Color'].default_value=(.15,.85,.5,1); p.inputs['Emission Strength'].default_value=2
parts=[]
def bind(obj,bone,material):
    obj.data.materials.append(material); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    vg=obj.vertex_groups.new(name=names[bone]); vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Humanoid skin','ARMATURE'); mod.object=rig
    obj.parent=rig; parts.append(obj); return obj
def box(name,loc,size,bone,material,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=C@Vector(loc)); o=bpy.context.object; o.name=name
    o.scale=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Machined edges','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return bind(o,bone,material)
def pos(b):return world[b].translation
def joint(b,r=.075):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=r,location=C@pos(b));o=bpy.context.object;o.name=b+' joint';return bind(o,b,dark)
def limb(a,b,width,material):
    start=pos(a); end=pos(b); d=end-start
    bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=width*.83,radius2=width,depth=d.length*.82,location=C@((start+end)/2))
    o=bpy.context.object;o.name=a+' armor'; o.rotation_mode='QUATERNION';o.rotation_quaternion=(C.to_3x3()@d).to_track_quat('Z','Y');return bind(o,a,material)
hip=pos('Hips');chest=pos('UpperChest'); head=pos('Head')
box('Pelvis',hip,(.29,.18,.21),'Hips',dark)
box('Copper belt',hip+Vector((0,.07,0)),(.34,.07,.25),'Hips',amber)
box('Abdominal core',pos('Spine')+Vector((0,.02,0)),(.25,.17,.20),'Spine',dark)
box('Breastplate',chest+Vector((0,-.025,0)),(.40,.31,.26),'UpperChest',teal,.055)
box('Reactor surround',chest+Vector((0,0,.145)),(.15,.16,.035),'UpperChest',amber)
box('Reactor',chest+Vector((0,0,.169)),(.08,.09,.02),'UpperChest',glow,.012)
joint('Neck',.065)
box('Helmet',head+Vector((0,.075,0)),(.29,.29,.26),'Head',ivory,.055)
box('Dark face',head+Vector((0,.075,.133)),(.245,.13,.025),'Head',dark,.025)
box('Single light visor',head+Vector((0,.095,.15)),(.205,.035,.015),'Head',glow,.008)
box('Helmet crest',head+Vector((0,.235,-.015)),(.07,.075,.22),'Head',amber,.012)
for side in ['Left','Right']:
    joint(side+'Shoulder'); joint(side+'UpperArm',.105)
    limb(side+'UpperArm',side+'LowerArm',.085,teal);joint(side+'LowerArm',.072)
    limb(side+'LowerArm',side+'Hand',.08,ivory);joint(side+'Hand',.065)
    box(side+' mitten',pos(side+'Hand'),(.13,.105,.13),side+'Hand',amber)
    limb(side+'UpperLeg',side+'LowerLeg',.115,teal);joint(side+'LowerLeg',.095)
    limb(side+'LowerLeg',side+'Foot',.10,ivory);joint(side+'Foot',.068)
    box(side+' boot',pos(side+'Foot')+Vector((0,-.01,.07)),(.19,.15,.32),side+'Foot',dark)
    box(side+' knee plate',pos(side+'LowerLeg')+Vector((0,0,.07)),(.15,.13,.08),side+'LowerLeg',amber)
# One skinned mesh, separate rigidly weighted islands retain the mechanical silhouette.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join(); character=bpy.context.object;character.name='Ember_Armor'
rig.select_set(True); bpy.context.view_layer.objects.active=rig
rig.animation_data_create(); action=bpy.data.actions.new('Rest_TPose');rig.animation_data.action=action
rig.pose.bones[names['Hips']].keyframe_insert(data_path='rotation_quaternion',frame=1)
rig.pose.bones[names['Hips']].keyframe_insert(data_path='rotation_quaternion',frame=2)
bpy.context.scene.frame_set(1)
(ROOT/'Source').mkdir(exist_ok=True);(ROOT/'Assets/Character').mkdir(exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Source/Ember.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'Assets/Character/ember.glb'),export_format='GLB',use_selection=True,export_animations=True,export_yup=True)
print('EMBER_CREATED',len(character.data.vertices),'vertices',len(arm.bones),'bones')
