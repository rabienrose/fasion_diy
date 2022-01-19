extends Spatial

var cloth_w=2
var cloth_h=2
var node_dense=10
var node_w_num
var node_h_num
var total_node_num=0
var update_step=0.5
var update_cur_time=0
var node_debug:MeshInstance=null
var mesh_debug:MeshInstance=null
var link_debug:MeshInstance=null
var mesh_node:MeshInstance=null
var do_simu=false

var gravity=Vector3(0,-9.8,0)

var sn = OpenSimplexNoise.new()
var mdt = MeshDataTool.new()

enum LinkType{
    SIDE,
    DIAG,
    BEND
}

class NodeCloth:
    var p:Vector3
    var last_p:Vector3
    var v:Vector3
    var im:float
    var f:Vector3
    var id:int
    func NodeCloth():
        f=Vector3(0,0,0)
    func set_weigth(w):
        if w==-1:
            im=0
        else:
            im=1/w
    

class LinkCloth:
    var r_l:float
    var st:float
    var node1:NodeCloth
    var node2:NodeCloth
    var r_l_2:float
    var type:int
    func set_r_l(_r_l):
        r_l=_r_l
        r_l_2=r_l*r_l

var nodes=Array()
var links=Array()

func cal_v_ind_above_2(v_id):
    return v_id+node_w_num*2
    
func cal_v_ind_right_2(v_id):
    return v_id+2

func cal_v_ind_above(v_id):
    return v_id+node_w_num
    
func cal_v_ind_right(v_id):
    return v_id+1
    
func cal_v_ind_right_above(v_id):
    return v_id+node_w_num+1

func cal_v_ind_left_above(v_id):
    return v_id+node_w_num-1

func cal_normals():
    sn.period = 0.7
    mdt.create_from_surface(mesh_node.mesh, 0)
    for i in range(mdt.get_face_count()):
        var a = mdt.get_face_vertex(i, 0)
        var b = mdt.get_face_vertex(i, 1)
        var c = mdt.get_face_vertex(i, 2)
        mdt.set_vertex_normal(a, Vector3(0,0,0))
        mdt.set_vertex_normal(b, Vector3(0,0,0))
        mdt.set_vertex_normal(c, Vector3(0,0,0))
    for i in range(mdt.get_face_count()):
        var a = mdt.get_face_vertex(i, 0)
        var b = mdt.get_face_vertex(i, 1)
        var c = mdt.get_face_vertex(i, 2)
        var ap = mdt.get_vertex(a)
        var bp = mdt.get_vertex(b)
        var cp = mdt.get_vertex(c)
        var n = (bp - cp).cross(ap - bp).normalized()
        mdt.set_vertex_normal(a, n + mdt.get_vertex_normal(a))
        mdt.set_vertex_normal(b, n + mdt.get_vertex_normal(b))
        mdt.set_vertex_normal(c, n + mdt.get_vertex_normal(c))
    for i in range(mdt.get_vertex_count()):
        var v = mdt.get_vertex_normal(i).normalized()
        mdt.set_vertex_normal(i, v)
    mesh_node.mesh.surface_remove(0)
    mdt.commit_to_surface(mesh_node.mesh)

func show_link_err():
    var error=0
    var max_err=-1
    var min_err=-1
    for i in range(links.size()):
        var link = links[i]
        var d_vec = (link.node2.p - link.node1.p)
        var link_l = d_vec.length()
        var err=abs(link.r_l - link_l)
        if min_err ==-1 or err<min_err:
            min_err=err
        if max_err ==-1 or err>max_err:
            max_err=err
        error=error+err
    print("avg: ",error/links.size()," max: ",max_err," min: ",min_err)

func debug_mesh():
    if mesh_debug !=null:
        mesh_debug.queue_free()
    mesh_debug = MeshInstance.new()
    mesh_debug.name="MeshDebug"
    var new_mesh = ArrayMesh.new()
    var arrays = Array()
    arrays.resize(ArrayMesh.ARRAY_MAX)
    var v_array=mesh_node.mesh.surface_get_arrays(0)
    arrays[ArrayMesh.ARRAY_VERTEX] = v_array[ArrayMesh.ARRAY_VERTEX]
    mdt.create_from_surface(mesh_node.mesh, 0)
    var indice=PoolIntArray()
    var colors=PoolColorArray()
    colors.resize(v_array[ArrayMesh.ARRAY_VERTEX].size())
    for i in range(mdt.get_edge_count()):
        var v1= mdt.get_edge_vertex(i,0)
        var v2= mdt.get_edge_vertex(i,1)
        colors[v1]=Color.black
        colors[v2]=Color.black
        indice.append(v1)
        indice.append(v2)
    arrays[ArrayMesh.ARRAY_INDEX]=indice
    arrays[ArrayMesh.ARRAY_COLOR] = colors
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
    mesh_debug.mesh=new_mesh
    add_child(mesh_debug)
    var mat=SpatialMaterial.new()
    mat.vertex_color_use_as_albedo=true
    mat.params_line_width=2
    mat.flags_unshaded=true
    mesh_debug.mesh.surface_set_material(0,mat)

func debug_link(link_type):
    if link_debug !=null:
        link_debug.queue_free()
    link_debug = MeshInstance.new()
    link_debug.name="LinkDebug"
    var new_mesh = ArrayMesh.new()
    var arrays = Array()
    arrays.resize(ArrayMesh.ARRAY_MAX)
    var vertice=PoolVector3Array()
    var colors=PoolColorArray()
    for i in range(links.size()):
        var link=links[i]
        if link.type!=link_type:
            continue
        var p1=link.node1.p
        var p2=link.node2.p
        vertice.append(p1)
        vertice.append(p2)
        var diff=(p1-p2).length()/link.r_l
        var sat=abs(diff-1.0)
        var hue=diff-0.5
        if hue<0:
            hue=0
        if hue>1:
            hue=1
        var c=Color.from_hsv(hue,sat,1)
        colors.append(c)
        colors.append(c)
    arrays[ArrayMesh.ARRAY_VERTEX]=vertice
    arrays[ArrayMesh.ARRAY_COLOR]=colors
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
    link_debug.mesh=new_mesh
    add_child(link_debug)
    var mat=SpatialMaterial.new()
    mat.vertex_color_use_as_albedo=true
    mat.flags_unshaded=true
    link_debug.mesh.surface_set_material(0,mat)
    
func debug_nodes():
    if node_debug !=null:
        node_debug.queue_free()
    node_debug = MeshInstance.new()
    node_debug.name="NodeDebug"
    var new_mesh = ArrayMesh.new()
    var v_array=mesh_node.mesh.surface_get_arrays(0)
    var arrays = Array()
    arrays.resize(ArrayMesh.ARRAY_MAX)
    arrays[ArrayMesh.ARRAY_VERTEX] = v_array[ArrayMesh.ARRAY_VERTEX]
    var colors=PoolColorArray()
    for i in range(mesh_node.mesh.surface_get_array_len(0)):
        if i==0:
            colors.append(Color.red)
        else:
            colors.append(Color.blue)
    
    arrays[ArrayMesh.ARRAY_COLOR] = colors
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
    node_debug.mesh=new_mesh
    add_child(node_debug)
    var mat=SpatialMaterial.new()
    mat.flags_use_point_size=true
    mat.vertex_color_use_as_albedo=true
    mat.params_point_size=2
    mat.flags_unshaded=true
    node_debug.mesh.surface_set_material(0,mat)

func add_link(node1_id, node2_id, st, r_l, link_type):
    var link:=LinkCloth.new()
    link.node1=nodes[node1_id]
    link.node2=nodes[node2_id]
    link.set_r_l(r_l)
    link.st=st
    link.type=link_type
    links.append(link)

func node_coor_2_id(pos:Vector2):
    return pos.y*node_w_num+pos.x

func node_id_2_coor(id)->Vector2:
    var ret:=Vector2()
    ret.y=floor(id/node_w_num)
    ret.x=id-ret.y*node_w_num
    return ret

func _ready():
    mesh_node=get_node("ClothMesh")
    mesh_node.mesh=mesh_node.mesh
    node_w_num=node_dense*cloth_w+1
    node_h_num=node_dense*cloth_h+1
    total_node_num=node_w_num*node_h_num
    var new_mesh = ArrayMesh.new()
    var vertices = PoolVector3Array()
    var normals = PoolVector3Array()
    vertices.resize(node_w_num*node_h_num)
    normals.resize(node_w_num*node_h_num)
    var w_step=cloth_w/float(node_w_num)
    var h_step=cloth_h/float(node_h_num)
    var v_count=0
    for j in range(node_h_num):
        for i in range(node_w_num):
            var r_z = sn.get_noise_2d(i*5,j*5)*1
            # var r_z = rand_range(-0.9,0.9)
            vertices[v_count]=Vector3(i*w_step,j*h_step,r_z)
            normals[v_count]=Vector3(0,0,1)
            v_count=v_count+1
    var arrays = Array()
    arrays.resize(ArrayMesh.ARRAY_MAX)
    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    var indice=PoolIntArray()
    indice.resize((node_w_num-1)*(node_h_num-1)*6)
    var ind_count=0
    for j in range(node_h_num-1):
        for i in range(node_w_num-1):
            var v_id=i+j*node_w_num
            indice[ind_count]=v_id
            ind_count=ind_count+1
            indice[ind_count]=cal_v_ind_above(v_id)
            ind_count=ind_count+1
            indice[ind_count]=cal_v_ind_right_above(v_id)
            ind_count=ind_count+1
            indice[ind_count]=v_id
            ind_count=ind_count+1
            indice[ind_count]=cal_v_ind_right_above(v_id)
            ind_count=ind_count+1
            indice[ind_count]=cal_v_ind_right(v_id)
            ind_count=ind_count+1
    arrays[ArrayMesh.ARRAY_INDEX] = indice
    new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var mat=SpatialMaterial.new()
    mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
    new_mesh.surface_set_material(0,mat)
    mesh_node.mesh=new_mesh
    translation=Vector3(-cloth_w/2.0,0,0)
    cal_normals()
    nodes.resize(total_node_num)
    var fix_node_list={}
    fix_node_list[int(node_coor_2_id(Vector2(0, node_h_num-1)))]=1
    fix_node_list[int(node_coor_2_id(Vector2(node_w_num-1, node_h_num-1)))]=1
    for i in range(mesh_node.mesh.surface_get_array_len(0)):
        var node := NodeCloth.new()
        node.id=i
        node.p=mdt.get_vertex(i)
        node.last_p=node.p
        node.v=Vector3(0,0,0)
        if fix_node_list.has(i):
            node.set_weigth(-1)
        else:
            node.set_weigth(0.01)
        nodes[i]=node
    for j in range(node_h_num):
        for i in range(node_w_num):
            var v_id=i+j*node_w_num
            if j<node_h_num-1:
                add_link(v_id, cal_v_ind_above(v_id), 1, h_step, LinkType.SIDE)
            if i<node_w_num-1:
                add_link(v_id, cal_v_ind_right(v_id), 1, w_step, LinkType.SIDE)
            if i<node_w_num-1 and j<node_h_num-1:
                add_link(v_id, cal_v_ind_right_above(v_id), 1, Vector2(w_step, h_step).length(), LinkType.DIAG)
            if i>0 and j<node_h_num-1:
                add_link(v_id, cal_v_ind_left_above(v_id), 1, Vector2(w_step, h_step).length(), LinkType.DIAG)
            if i<node_w_num-2:
                add_link(v_id, cal_v_ind_right_2(v_id), 1, w_step*2, LinkType.BEND)
            if j<node_h_num-2:
                add_link(v_id, cal_v_ind_above_2(v_id), 1, h_step*2, LinkType.BEND)

func solve_links():
    for i in range(links.size()):
        var link = links[i]
        var node_a = link.node1
        var node_b = link.node2
        var d_vec = node_b.p - node_a.p
        var len_2 = d_vec.length_squared()
        if link.r_l_2 + len_2 > 0.00001 and node_a.im+node_b.im>0:
            var k = (link.r_l_2 - len_2)/(link.st * (link.r_l_2 + len_2)*1)
            node_a.p -= d_vec * (k * node_a.im/(node_a.im+node_b.im))
            node_b.p += d_vec * (k * node_b.im/(node_a.im+node_b.im))

func _physics_process(delta):
    if do_simu==false:
        return
    var t1=OS.get_ticks_msec()
    var inv_delta=1/delta
    for node in nodes:
        if node.im==0:
            continue
        node.v=node.v+gravity*delta
        node.p = node.last_p + node.v * delta
    for _i in range(5):
        solve_links()
    for node in nodes:
        if node.im==0:
            continue
        node.v = (node.p - node.last_p) * inv_delta
        node.last_p = node.p
    var t2=OS.get_ticks_msec()
    mdt.create_from_surface(mesh_node.mesh, 0)
    for i in range(len(nodes)):
        var node=nodes[i]
        mdt.set_vertex(i, node.p)
    mesh_node.mesh.surface_remove(0)
    mdt.commit_to_surface(mesh_node.mesh)
    cal_normals()
    var t3=OS.get_ticks_msec()
    print("phy t: ",int(t2-t1)," mesh t: ",int(t3-t2))
    
func _input(event):
    if event is InputEventKey and event.is_pressed():
        if event.scancode==KEY_Q:
            if mesh_debug!=null and mesh_debug.visible==true:
                mesh_debug.queue_free()
                mesh_debug=null
            else:
                debug_mesh()
        if event.scancode==KEY_W:
            mesh_node.visible=!mesh_node.visible
        if event.scancode==KEY_D or event.scancode==KEY_F or event.scancode==KEY_G:
            if link_debug!=null and link_debug.visible==true:
                link_debug.queue_free()
                link_debug=null
            else:
                if event.scancode==KEY_D:
                    debug_link(LinkType.SIDE)
                if event.scancode==KEY_F:
                    debug_link(LinkType.DIAG)
                if event.scancode==KEY_G:
                    debug_link(LinkType.BEND)
        if event.scancode==KEY_E:
            if node_debug!=null and node_debug.visible==true:
                node_debug.queue_free()
                node_debug=null
            else:
                debug_nodes()
        if event.scancode==KEY_A:
            do_simu=!do_simu
        if event.scancode==KEY_S:
            show_link_err()

func predict_motion(delta):
    var inv_delta=delta
    var max_displacement = 1000.0
    var clamp_delta_v = max_displacement * inv_delta
    for node in nodes:
        node.v=node.v+gravity*delta
        node.last_p = node.p
        var delta_v = node.f * node.im * delta
        for i in range(3):
            if delta_v[i]<-clamp_delta_v:
                delta_v[i]=-clamp_delta_v
            if delta_v[i]>clamp_delta_v:
                delta_v[i]=clamp_delta_v
        node.v = node.v+delta_v
        node.x = node.x+node.v * delta
        node.f = Vector3()

    
            

