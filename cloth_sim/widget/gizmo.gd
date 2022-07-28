extends Spatial

var up_arrow:MeshInstance
var right_arrow:MeshInstance
var front_arrow:MeshInstance
var widgt_scale=0.2


func make_a_patch(length, width, color):
    var new_mesh = ArrayMesh.new()
    var vertices = PoolVector3Array()
    var h_width=width/2.0
    vertices.append(Vector3(h_width,0,0))
    vertices.append(Vector3(-h_width,0,0))
    vertices.append(Vector3(-h_width,0,length))
    vertices.append(Vector3(h_width,0,length))
    var indice=PoolIntArray()
    indice.append(0)
    indice.append(1)
    indice.append(2)
    indice.append(0)
    indice.append(2)
    indice.append(3)
    var arrays = Array()
    arrays.resize(ArrayMesh.ARRAY_MAX)
    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    arrays[ArrayMesh.ARRAY_INDEX] = indice
    print(arrays)
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var mat=SpatialMaterial.new()
    mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
    mat.albedo_color=color
    mat.flags_no_depth_test=true
    mat.flags_unshaded=true
    mat.flags_fixed_size =true
#    mat.params_billboard_mode=SpatialMaterial.BILLBOARD_FIXED_Y
    new_mesh.surface_set_material(0,mat)
    var mesh_node=MeshInstance.new()
    mesh_node.mesh=new_mesh
    return mesh_node

func _ready():
    up_arrow = make_a_patch(1, 0.05, Color.green)
    right_arrow = make_a_patch(1, 0.05, Color.red)
    front_arrow = make_a_patch(1, 0.05, Color.blue)
    up_arrow.scale=Vector3(widgt_scale,widgt_scale,widgt_scale)
    right_arrow.scale=Vector3(widgt_scale,widgt_scale,widgt_scale)
    front_arrow.scale=Vector3(widgt_scale,widgt_scale,widgt_scale)
    add_child(up_arrow)
    add_child(right_arrow)
    add_child(front_arrow)
    up_arrow.rotate_x(-3.1415926/2)
    right_arrow.rotate_y(3.1415926/2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
