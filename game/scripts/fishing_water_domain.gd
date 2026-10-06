class_name FishingWaterDomain
extends RefCounted
## Static, imported geometry is authoritative for castable water. Queries use
## stage coordinates, so rotated river-bank stations and translated boats agree
## with the visible shore, sandbars and rocks instead of assuming y=0 is water.
const FLOAT_CLEARANCE: float = 1.25
const FLOAT_VIEW_OFFSET := Vector3(0.34,1.16,3.05)
var _geometry: Array[Dictionary] = []

func rebuild(stage: Node3D, roots: Array[Node3D]) -> void:
	_geometry.clear()
	for node: Node3D in roots: _collect(stage,node)

func _collect(stage: Node3D, node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var label: String=str(node.name)
		# Foliage/reeds are not solid ground. The authored canopy clearing and
		# the separate visibility audit cover them; never interpret leaf triangles
		# high above a river as its bed. Trunks/branches/rocks remain obstacles.
		if not label.begins_with("Foliage") and label not in ["Reed","Cattail"]:
			var mesh: TriangleMesh=node.mesh.generate_triangle_mesh()
			if mesh != null:
				var frame: Transform3D=stage.global_transform.affine_inverse()*node.global_transform
				_geometry.append({"mesh":mesh,"inverse":frame.affine_inverse(),"frame":frame,"name":label})
	for child: Node in node.get_children(): _collect(stage,child)

func first_obstacle(begin: Vector3, end: Vector3) -> Dictionary:
	var closest: Dictionary={}
	var distance: float=INF
	for shape: Dictionary in _geometry:
		var hit: Dictionary=shape.mesh.intersect_segment(shape.inverse*begin,shape.inverse*end)
		if hit.is_empty(): continue
		var at: Vector3=shape.frame*hit.position
		var candidate: float=begin.distance_squared_to(at)
		if candidate<distance:
			distance=candidate
			closest={"position":at,"name":shape.name}
	return closest

func is_open_water(at: Vector3, clearance: float = FLOAT_CLEARANCE) -> bool:
	# Stay on the actual subdivided near-water mesh, with room for drift/waves.
	if absf(at.x)+clearance>77.5 or at.z-clearance < -148.0 or at.z+clearance>32.0: return false
	# A grid covers the float's full travel footprint, including its submerged
	# body. The lower cutoff leaves more room than the longest 0.18m dip.
	for x: int in range(-2,3):
		for z: int in range(-2,3):
			var probe:=at+Vector3(x,0,z)*clearance*0.5
			if not first_obstacle(Vector3(probe.x,200,probe.z),Vector3(probe.x,-0.38,probe.z)).is_empty(): return false
	return true

func has_clear_float_view(at: Vector3) -> bool:
	var eye: Vector3=at+FLOAT_VIEW_OFFSET
	for x: float in [-0.65,0.0,0.65]:
		for z: float in [-0.65,0.0,0.65]:
			if not first_obstacle(eye,at+Vector3(x,0.06,z)).is_empty(): return false
	return true

func resolve_cast(requested: Vector3) -> Vector3:
	if is_open_water(requested) and has_clear_float_view(requested): return requested
	# Keep the requested distance first. Only if its entire arc is blocked do
	# we search farther water. No screen coordinates enter this calculation.
	var distance: float=Vector2(requested.x,requested.z).length()
	var direction: float=atan2(-requested.x,-requested.z)
	for extra: float in [0.0,1.5,3.0,5.0,8.0,12.0,18.0]:
		for turn: float in [0.0,-10.0,10.0,-20.0,20.0,-35.0,35.0,-50.0,50.0,-70.0,70.0]:
			var angle: float=direction+deg_to_rad(turn)
			var candidate:=Vector3(-sin(angle),0,-cos(angle))*(distance+extra)
			if is_open_water(candidate) and has_clear_float_view(candidate): return candidate
	return Vector3(INF,INF,INF)
