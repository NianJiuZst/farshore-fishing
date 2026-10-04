# 海洋版：用户本机签名交接

新应用为 `org.farshore.fishing.ocean` / `远岸钓鱼·海洋`，1.3.0 / versionCode7。它与原 `org.farshore.fishing.preview` 并存，不覆盖原应用或读取其私人存档。不要卸载旧版。

## 私钥在自己的 Mac 上保管

密钥创建、口令输入和私密备份由用户在自己的电脑完成。云端不生成、接收、上传或保存私钥、口令，也不将加密私钥包上传 GitHub、聊天或文件库。本次已由用户生成 PKCS12、RSA3072、别名 `farshore-ocean`。口令通过本机工具的隐藏交互提示输入，不写进命令、源码、聊天或环境变量。

签名之前，须由用户保存并核验一份独立、可恢复的私密备份。密钥文件和其口令需要长期保留，未来同包名更新依赖同一签名。不要仅依赖临时工作区或仅有一个本机副本。交回的唯一密钥相关信息是公钥证书 SHA256；它不是私钥。

取得这个公开指纹后，将它固定进源码身份定义并重新导出 APK。未配置的签名标记会让正式构建/验证失败，不允许以空值或旧证书替代。

## 只传递签名前 APK 和公开校验资料

签名输入是经完整内容审计、Vulkan声明规范化和16KiB ZIP对齐的未签名 ARM64 APK。文件名明确包含 `UNSIGNED-INTERNAL`；它不是可安装交付物，不发布到正式下载页。交接时同时提供准确的源码提交、输入 SHA256、公开证书指纹和校验报告。

Mac 只需官方 Java21、Android SDK build-tools36.0.0或36.1.0（须支持`zipalign -P16`和v2/v3签名），以及 Python3.11+；不必下载完整3D美术源文件、Godot编辑器、模拟器或运行 adb。官方工具安装不得绕过平台安全提示。已在用户Mac准备好的交互式签名工具为本次首选流程；`tools/sign_ocean_apk_locally.py` 是可选的公开参考实现，不要求重复生成密钥或重复配置。

```sh
python3 sign_ocean_apk_locally.py \
  --input '/path/to/Farshore-1.3.0-UNSIGNED-INTERNAL.apk' \
  --output '/path/to/Farshore-1.3.0-arm64.apk' \
  --build-tools "$HOME/Library/Android/sdk/build-tools/36.1.0" \
  --keystore '/your/private/farshore-ocean-release.p12' \
  --alias farshore-ocean \
  --expected-input-sha256 '公布的输入文件SHA256' \
  --expected-certificate-sha256 '用户本机生成的公钥证书SHA256' \
  --backup-confirmed
```

脚本在提示后读取隐藏口令，不生成密钥、不联网、不安装应用、不改动输入文件。它核验包名、版本、架构、权限、74鱼/12饵/9地区/18钓点、公开签名指纹、v2/v3签名和16KiB对齐，生成仅含公开字段的签名报告。

只返回签名后的 APK 和公开报告。云端还会对返回 APK 完整复核资源、源码对应、签名和哈希，然后才发布。Mac静态签名检查不等于Android真机运行、旧版覆盖安装或性能测试。

本次用户本机公开证书SHA256已核验并固定：`a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716`。这是公钥证书指纹，不含私钥或口令。
