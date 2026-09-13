"""Isolate build settings and use the executor's existing network configuration.

This neither generates credentials nor modifies system settings/certificate stores.
The signing key is only referenced as an existing file to suppress Godot's automatic
debug-keystore creation. The APK is signed separately with apksigner password files.
"""
from pathlib import Path
import json
import os
import urllib.parse

root = Path(os.environ["FARSHORE_ROOT"])
key = Path(os.environ["FARSHORE_EXISTING_KEY"])
assert key.is_file(), "Existing, explicitly authorized release key required"
config = Path(os.environ["XDG_CONFIG_HOME"]) / "godot"
config.mkdir(parents=True, exist_ok=True)
settings = '\n'.join([
    '[gd_resource type="EditorSettings" format=3]', '', '[resource]',
    'export/android/java_sdk_path=' + json.dumps(os.environ["JAVA_HOME"]),
    'export/android/android_sdk_path=' + json.dumps(os.environ["ANDROID_HOME"]),
    'export/android/debug_keystore=' + json.dumps(str(key)),
    'export/android/debug_keystore_user=""',
    'export/android/debug_keystore_pass=""',
    '',
])
(config / 'editor_settings-4.6.tres').write_text(settings)
templates = Path(os.environ["XDG_DATA_HOME"]) / 'godot/export_templates/4.6.3.stable'
templates.parent.mkdir(parents=True, exist_ok=True)
if not templates.exists():
    templates.symlink_to(root / 'tools/godot-templates/4.6.3.stable')
props = ['org.gradle.daemon=false', 'org.gradle.workers.max=2', 'org.gradle.jvmargs=-Xmx2048m']
for protocol in ['http', 'https']:
    proxy = urllib.parse.urlsplit(os.environ.get(protocol.upper() + '_PROXY', ''))
    if proxy.hostname:
        if proxy.username or proxy.password:
            raise RuntimeError('Credential-bearing proxy requires manual secure configuration')
        props += [f'systemProp.{protocol}.proxyHost={proxy.hostname}',
                  f'systemProp.{protocol}.proxyPort={proxy.port or 80}']
# Reuse an already-configured system trust store when the executor supplies one.
# Do not import trust certificates or disable HTTPS verification.
system_trust = Path('/etc/ssl/certs/java/cacerts')
if os.environ.get('SSL_CERT_FILE') and system_trust.is_file():
    props.append('systemProp.javax.net.ssl.trustStore=' + str(system_trust))
gradle_home = Path(os.environ['GRADLE_USER_HOME'])
gradle_home.mkdir(parents=True, exist_ok=True)
(gradle_home / 'gradle.properties').write_text('\n'.join(props) + '\n')
