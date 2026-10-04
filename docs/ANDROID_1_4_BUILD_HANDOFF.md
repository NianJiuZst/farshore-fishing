# 1.4.0 云端构建与本机签名交接

用户已授权本次代码推送及最终 Release 附件；未签名 APK 只用于内部交接。使用本任务专用远端分支的最终确切 commit，不修改 `main` 来临时试包。所有制作文件、原始生成插画和 37 个新模型源都随 commit 交付。

## 不变的更新身份

| 字段 | 固定值 |
| --- | --- |
| 应用版本 | `1.4.0` |
| Android versionCode | `8`（1.3.0 为 `7`） |
| 包名 | `org.farshore.fishing.ocean` |
| 签名证书 SHA256 | `a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716` |
| 用户 Mac 既有签名文件 | `~/Farshore-Signing/private/farshore-ocean.p12` |
| 别名 | `farshore-ocean` |
| 存档 | 原 schema 2，蓝鲸使用可选扩展；旧进度、74 ID、记录和备份保持 |

不要将私钥、密码或新建密钥带到云端。密码由用户在 Mac 本地工具提示时手动输入。用户若安装此同包同证书、较高 versionCode 的正式包，应选择覆盖更新；先保留其游戏内导出的存档备份。

## 使用既有 Android 36 工具链

沿用云端已验证的 Godot **4.6.3.stable.official.7d41c59c4**、相应官方 Android ARM64 Release 模板、Android build-tools **36.1.0** 和已验证的 Godot Android exporter 源。保留 Mobile/Vulkan、高画质、ARM64、16KB native/ZIP 对齐及禁用 OpenGL 兜底；本次没有本机 SDK 安装或许可证接受步骤。

1. 检出最终 commit；用 `tools/release_source_zip.py` 创建逐 Git blob 校验的源码 ZIP 和对应 manifest。输出使用任务拥有的独立目录，不能覆盖旧档案；Python 必须非 `-O` 且具备 `hashlib.file_digest`（3.11+）。
2. 在独立 staging 项目调用 `tools/android_unsigned_handoff.py`。工具复制完整源码、排除 `.godot` 缓存与已有 Android build、在唯一拥有的副本中移除测试，关闭签名与 runnable presets，保留源码。工具同时检查 111 模型、222 图片、111 科学图鉴、PBR 材质、导入图像 RGBA8、Vulkan renderer、ARM64、API 身份、native bytes 和无私钥材料。
3. 把通过全部静态门槛的 unsigned 包、完整审计目录和源 commit/hash 交回用户 Mac。没有签名的包不能作为正式 Release APK。

示意命令（模板、exporter、输出目录指向已有资源；不是下载或安装步骤）：

```sh
python3 tools/release_source_zip.py \
  --commit FINAL_COMMIT \
  --output /owned/output/Farshore-1.4.0-source.zip \
  --prefix Farshore-1.4.0-source \
  --manifest /owned/output/Farshore-1.4.0-source-manifest.json

GODOT=/existing/godot-4.6.3 python3 tools/android_unsigned_handoff.py \
  --source-zip /owned/output/Farshore-1.4.0-source.zip \
  --source-manifest /owned/output/Farshore-1.4.0-source-manifest.json \
  --template /existing/android-arm64-release.apk \
  --upstream-source /existing/android-export-plugin.cpp \
  --expected-certificate-sha256 a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716 \
  --output /owned/output/Farshore-1.4.0-UNSIGNED-INTERNAL.apk \
  --audit /owned/output/unsigned-audit \
  --staging-parent /owned/staging
```

输入/output/staging 的祖先不得为符号链接；macOS 的 `/tmp`、`/var` 别名不能作为显式 staging 目录，使用规范路径。所有失败保持原日志，不能绕过源哈希、身份或素材完整性检查来出包。

## 签名后验证与发布附件

由用户本机使用既有证书完成签名后，再验证实际 APK 的 v2/v3 签名和证书 SHA256、包名、versionCode、Mobile/Vulkan、ARM64、16KB 对齐、111 模型及 222 图像内容，与 unsigned 模板 native 字节和源快照一致。使用仓库已有签名验证工具，不仅凭文件名判断更新身份。

保留代码 Git commit、源码 ZIP/manifest、签名 APK、构建/校验报告、测试截图及 SHA256 清单作为最终公开附件。私钥与密码不属于附件。Release 的源码标签必须指向最终实际构建 commit。最终手机验收应包含 1.3.0 原存档覆盖更新、普通新鱼抛竿起鱼、红海三钓点、蓝鲸三阶段完成/重试/后台暂停和巨物完整展示。开发 Mac 的原生 Vulkan 画面与数学视口检查不代替 Android 16 / Snapdragon 8 Elite 的真机帧率或安全区验收。

已完成的本地证据位于 [本地审查记录](OCEAN_DIVERSITY_1_4_REVIEW.md) 与 `docs/evidence/ocean-diversity/qa/`。真实截图及生成插画制作来源均已提交，未借用旧图充当新增内容。
