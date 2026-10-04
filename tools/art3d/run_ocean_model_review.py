#!/usr/bin/env python3
"""Import and render the exact 37 GLBs in a disposable Godot studio.

Only model assets and a neutral studio harness are copied. The player's game,
installed settings and saved profile are never opened by this project. On macOS
the inherited home value is omitted in the child so user:// stays under the
disposable working directory; no global environment value is modified.
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


def run(command,project,environment,path,timeout):
    with path.open("w") as log:
        completed=subprocess.run(command,cwd=project,env=environment,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
    if completed.returncode:
        print(path.read_text()[-16000:],flush=True)
        raise SystemExit(completed.returncode)


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--godot",type=Path,required=True);parser.add_argument("--output",type=Path,required=True);args=parser.parse_args()
    output=args.output.resolve();output.mkdir(parents=True,exist_ok=True)
    profiles_path=ROOT/"tools/art3d/ocean_profiles.json";profiles=json.loads(profiles_path.read_text())["species"]
    with tempfile.TemporaryDirectory(prefix="farshore-ocean-model-studio-",dir="/tmp") as isolated:
        project=Path(isolated)/"project";assets=project/"assets/3d";assets.mkdir(parents=True)
        hashes={}
        for profile in profiles:
            source=ROOT/"game/assets/3d"/(profile["id"]+".glb")
            target=assets/source.name;shutil.copyfile(source,target)
            a=hashlib.sha256(source.read_bytes()).hexdigest();b=hashlib.sha256(target.read_bytes()).hexdigest();assert a==b
            hashes[profile["id"]]=a
        (project/"project.godot").write_text('''config_version=5
[application]
config/name="Farshore Ocean Model Studio"
config/features=PackedStringArray("4.6", "Mobile")
[display]
window/size/viewport_width=960
window/size/viewport_height=640
window/size/window_width_override=960
window/size/window_height_override=640
window/dpi/allow_hidpi=false
[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
anti_aliasing/quality/msaa_3d=2
textures/vram_compression/import_etc2_astc=true
shader_cache/enabled=false
[debug]
gdscript/warnings/untyped_declaration=0
''')
        shutil.copyfile(ROOT/"tools/art3d/capture_ocean_models.gd",project/"capture_ocean_models.gd")
        environment={k:v for k,v in os.environ.items() if k!="HOME"}
        environment["FARSHORE_ISOLATED_ROOT"]=isolated
        environment["XDG_DATA_HOME"]=str(Path(isolated)/"data")
        environment["XDG_CACHE_HOME"]=str(Path(isolated)/"cache")
        environment["XDG_CONFIG_HOME"]=str(Path(isolated)/"config")
        godot_source=args.godot.resolve()
        if os.sys.platform=="darwin" and godot_source.parents[2].suffix==".app":
            # The user's existing portable bundle can choose editor_data next
            # to itself. A checksum-identical disposable copy keeps even editor
            # preferences in the audit directory instead of that toolchain.
            bundle=Path(isolated)/"Godot.app"
            shutil.copytree(godot_source.parents[2],bundle,symlinks=True)
            godot_copy=bundle/"Contents/MacOS"/godot_source.name
            assert hashlib.sha256(godot_source.read_bytes()).digest()==hashlib.sha256(godot_copy.read_bytes()).digest()
            executable=str(godot_copy)
        else:executable=str(godot_source)
        print("OCEAN_STUDIO_IMPORT: 37 checksum-identical GLBs, disposable project",flush=True)
        run([executable,"--headless","--import","--path",str(project),"--log-file",str(output/"import_engine.log")],project,environment,output/"import.log",180)
        run([executable,"--headless","--path",str(project),"--script","res://capture_ocean_models.gd","--check-only","--log-file",str(output/"parse_engine.log")],project,environment,output/"parse.log",40)
        print("OCEAN_STUDIO_GPU: Godot 4.6.3 Mobile / Vulkan",flush=True)
        run([executable,"--path",str(project),"--rendering-method","mobile","--rendering-driver","vulkan","--audio-driver","Dummy","--script","res://capture_ocean_models.gd","--log-file",str(output/"gpu_engine.log"),"--",str(profiles_path),str(output)],project,environment,output/"gpu.log",180)
        record={"model_glb_sha256":hashes,"source_profile_sha256":hashlib.sha256(profiles_path.read_bytes()).hexdigest(),"rendering_method":"mobile","rendering_driver":"vulkan","disposable_project":True,"player_save_access":False,"inherited_home_removed_in_child_only":True,"captures":sorted(p.name for p in output.glob("*.png"))}
        (output/"run.json").write_text(json.dumps(record,indent=2)+"\n")
        print((output/"gpu.log").read_text()[-7000:],flush=True)


if __name__=="__main__":main()
