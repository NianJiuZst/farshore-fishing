extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("validate")
func collect(node: Node, kind: String, result: Array) -> void:
    if node.is_class(kind): result.append(node)
    for child in node.get_children(): collect(child, kind, result)
func validate() -> void:
    var repo = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
    var ids = OS.get_cmdline_user_args()
    if ids.is_empty(): ids = PackedStringArray(["chinese_sturgeon", "olive_flounder", "european_plaice"])
    for species in ids:
        var doc = GLTFDocument.new()
        var state = GLTFState.new()
        var err = doc.append_from_file(repo.path_join("game/assets/3d/" + species + ".glb"), state)
        if err != OK:
            failures.append(species + " GLTFDocument error " + str(err)); continue
        var model = doc.generate_scene(state)
        if not model:
            failures.append(species + " no generated scene"); continue
        root.add_child(model)
        var skeletons: Array = []
        var players: Array = []
        var meshes: Array = []
        collect(model, "Skeleton3D", skeletons)
        collect(model, "AnimationPlayer", players)
        collect(model, "MeshInstance3D", meshes)
        if skeletons.size() != 1 or players.size() != 1:
            failures.append(species + " skeleton/player count"); model.free(); continue
        var sk: Skeleton3D = skeletons[0]
        var ap: AnimationPlayer = players[0]
        var clips: Dictionary = {}
        for clip in ["swim", "struggle", "breach", "landed"]:
            if not ap.has_animation(clip):
                failures.append(species + " missing " + clip); continue
            var animation = ap.get_animation(clip)
            ap.play(clip); ap.seek(0, true); ap.advance(0)
            var initial: Array[Quaternion] = []
            for bone in sk.get_bone_count(): initial.append(sk.get_bone_pose_rotation(bone))
            var moved: Array[String] = []
            for phase in [0.125, 0.25, 0.375]:
                ap.seek(animation.length * phase, true); ap.advance(0)
                for bone in sk.get_bone_count():
                    var bn = sk.get_bone_name(bone)
                    if initial[bone].angle_to(sk.get_bone_pose_rotation(bone)) > 0.0005 and not moved.has(bn): moved.append(bn)
            if moved.size() < 5: failures.append(species + " weak/missing " + clip + " playback")
            clips[clip] = {"seconds": animation.length, "tracks": animation.get_track_count(), "animated_bones": moved}
        var bounds = AABB()
        var first = true
        var skinned = 0
        var surfaces = 0
        for mesh: MeshInstance3D in meshes:
            var box: AABB = mesh.global_transform * mesh.get_aabb()
            bounds = box if first else bounds.merge(box); first = false
            if mesh.skin: skinned += 1
            surfaces += mesh.mesh.get_surface_count()
        if abs(bounds.size.x - 1.0) > 0.001: failures.append(species + " unnormalized rest length")
        if skinned != meshes.size(): failures.append(species + " unskinned mesh")
        var report = {"species": species, "godot_version": Engine.get_version_info().string, "skeletons": skeletons.size(), "animation_players": players.size(), "bone_count": sk.get_bone_count(), "meshes": meshes.size(), "skinned_meshes": skinned, "material_surfaces": surfaces, "aabb_size": [bounds.size.x, bounds.size.y, bounds.size.z], "clips": clips, "failures": failures.filter(func(s): return s.begins_with(species))}
        var out_path = "res://" + species + "/godot_validation.json"
        var file = FileAccess.open(out_path, FileAccess.WRITE)
        file.store_string(JSON.stringify(report, "  "))
        print("PROFILE_GODOT_VALIDATED ", JSON.stringify(report))
        model.free()
    quit(0 if failures.is_empty() else 1)
