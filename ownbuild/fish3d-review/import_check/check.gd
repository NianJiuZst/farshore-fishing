extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("run_check")
func walk(n: Node, klass: String, result: Array) -> void:
    if n.is_class(klass):
        result.append(n)
    for child in n.get_children():
        walk(child, klass, result)
func run_check() -> void:
    var results: Dictionary = {}
    for species in ["common_carp", "alligator_gar"]:
        var packed = load("res://" + species + ".glb") as PackedScene
        if not packed:
            failures.append(species + " missing PackedScene")
            continue
        var fish: Node3D = packed.instantiate()
        root.add_child(fish)
        var skels: Array = []
        var anims: Array = []
        var meshes: Array = []
        walk(fish, "Skeleton3D", skels)
        walk(fish, "AnimationPlayer", anims)
        walk(fish, "MeshInstance3D", meshes)
        if skels.size() != 1 or anims.size() != 1:
            failures.append(species + " wrong skeleton/player count")
            continue
        var sk: Skeleton3D = skels[0]
        var ap: AnimationPlayer = anims[0]
        var required = ["swim", "struggle", "breach", "landed"]
        var names: Array[String] = []
        for bn in sk.get_bone_count():
            names.append(sk.get_bone_name(bn))
        var clips: Dictionary = {}
        for clip in required:
            if not ap.has_animation(clip):
                failures.append(species + " missing " + clip)
                continue
            var animation: Animation = ap.get_animation(clip)
            ap.play(clip)
            ap.seek(0.0, true)
            ap.advance(0.0)
            var initial: Array[Quaternion] = []
            for bone in sk.get_bone_count():
                initial.append(sk.get_bone_pose_rotation(bone))
            var changed: Array[String] = []
            for phase in [0.125, 0.25, 0.375]:
                ap.seek(animation.length * phase, true)
                ap.advance(0.0)
                for bone in sk.get_bone_count():
                    var bone_name = sk.get_bone_name(bone)
                    if initial[bone].angle_to(sk.get_bone_pose_rotation(bone)) > 0.001 and not changed.has(bone_name):
                        changed.append(bone_name)
            if changed.size() < 5:
                failures.append(species + "/" + clip + " deformation not playing")
            clips[clip] = {"seconds": animation.length, "tracks": animation.get_track_count(), "changing_bones": changed}
        var surfaces = 0
        var skinned = 0
        var world_box = AABB()
        var first = true
        for mesh: MeshInstance3D in meshes:
            surfaces += mesh.mesh.get_surface_count()
            if mesh.skin: skinned += 1
            var box: AABB = mesh.global_transform * mesh.get_aabb()
            world_box = box if first else world_box.merge(box)
            first = false
        results[species] = {"bone_count": sk.get_bone_count(), "bones": names, "mesh_count": meshes.size(), "skinned_mesh_count": skinned, "material_surfaces": surfaces, "aabb_size": [world_box.size.x, world_box.size.y, world_box.size.z], "clips": clips}
        fish.queue_free()
    var result = {"godot_version": Engine.get_version_info().string, "failures": failures, "models": results}
    print("FISH_IMPORT_VERIFIED ", JSON.stringify(result))
    var file = FileAccess.open("res://godot_import_report.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(result, "  "))
    quit(0 if failures.is_empty() else 1)
