# 远岸钓记 · Farshore Fishing 1.1.0

一个简体中文、竖屏、完全离线的 Godot 2D 钓鱼旅行游戏。内容为 6 处水域、12 个钓点、44 个唯一真实鱼种、3 档装备和 4 类无限补给鱼饵。

## 游玩

1. 点击“继续我的旅程”。长按底部按钮蓄力，松手抛竿
2. 浮漂轻动只是试探；显示“咬钩了”后点击提竿
3. 按住收线，张力高时松手卸力。持续过紧会断线，松弛超过约 5 秒会脱钩
4. 钓获保存后出售或放生。两者都保留历史累计数量和独立的最长、最重纪录
5. 在图鉴查看资料与钓点线索。发现 3 / 8 / 14 / 20 / 28 个物种后，用旅币逐步解锁日本、挪威、地中海、密西西比与长江
6. 购买旅行竿和探深竿，进入更深钓点。基础装备与全部鱼饵可持续免费使用

普通尺寸鱼的自动化控线验证约 12.6–24.5 秒；较大个体更难。鱼种稀有度与个体罕见大尺寸是不同维度。

中华鲟作为虚拟保护观察条目，只能放归，不提供出售。观察与放归同样保留累计数量和真实个体纪录；游戏互动不对应现实捕捞。

## 安装与更新

- 目标：Android 10（API29）及以上的 ARM64 手机，目标 SDK36（Android16）
- 下载签名发行 APK，在手机允许对应下载应用“安装未知应用”后安装。具体系统设置位置依设备厂商而异
- 这是单机应用，不申请网络、账号、通讯录、定位、存储读取等权限；仅使用可关闭的 VIBRATE
- 覆盖更新必须保持相同包名、签名身份，并提升 versionCode；不要先卸载旧版本
- 本地存档在应用私有数据目录的 Godot user:// 下。系统普通文件浏览器通常不能直接访问
- 卸载、清除应用数据会丢失进度。本版没有云同步，不承诺跨安装保留
- 构建、静态检查、桌面、模拟器与真机验证严格分开，详见 docs/ACCEPTANCE.md 和 docs/ANDROID_TESTS.md

## 打开工程

使用官方 Godot 4.6.3 stable（7d41c59c4），导入 game/project.godot 后运行。Compatibility 渲染，无 C#、WebView 或后端。项目内包含所有运行素材、JSON、中文授权字体与音效。首次导入会重建 .godot 缓存，无需下载游戏内容。

## 新版界面

钓手与风景是主画面主体，顶部仅保留必要状态，侧边进入旅行/图鉴/收藏/行囊。底部金色按钮负责抛竿、提竿与收线。图鉴以鱼类插画为中心，钓获页有尺寸尺标，保护鱼提供明确的放归操作。

## 构建 Android

详见 docs/BUILD.md。匹配的官方模板、JDK、Android SDK 与 Gradle 精确版本记录在该文件。执行 tools/android_build.sh arm64。SDK 首次安装需自行接受其许可。签名通过环境变量指向独立的私钥与密码文件，源码不包含签名凭据。

## 自动化测试

从源码根目录执行（使用隔离数据目录，勿指向实际玩家存档）：

    XDG_DATA_HOME=/tmp/farshore-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/save_tests.gd
    XDG_DATA_HOME=/tmp/farshore-core-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/core_tests.gd

测试源码不导出到发行APK。详见 docs/SAVE_TESTS.md 与 docs/CORE_TESTS.md。

## 文件结构

- game/scripts/：类型化 GDScript 模块
- game/scenes/main.tscn：原生 Control 场景入口
- game/data/fish_a.json 至 fish_d.json：44 物种的单一来源分片
- game/data/world.json：水域、钓点、装备与鱼饵
- game/assets/：实际运行插画、缩略图、分层场景、音效与字体
- art_masters/：高清工作底稿与视觉审查联系表，运行不依赖这些文件
- docs/：内容、来源、素材清单、架构、构建与验收记录
- spec/：原始开发需求
- tools/：构建脚本；工具二进制和下载缓存不进入源码包

## 资料与许可

鱼类分布和形态参考鱼类数据库与海洋研究机构，逐物种链接见 docs/FISH_A_SOURCES.md、FISH_B_SOURCES.md、FISH_C_SOURCES.md、FISH_D_SOURCES.md。出现倍率、尺寸锚点、重量立方缩放、时间/天气、难度与稀有度是游戏调校，不冒充实测科研关系，也不提供现实垂钓法规建议。

鱼与场景为内置图像生成工具逐资产生成，经开发者形态与透明边缘检查；完整提示词、资料、生成方式与审核记录见 docs/ASSETS_*.json。没有复用未获授权的外部照片。生成来源不构成独占权利或专业物种鉴定保证。中文字体使用 Noto Sans CJK（SIL OFL），详见 docs/FONT_LICENSE.txt。Godot 及第三方库许可在 game/data/GODOT_LICENSE.txt，游戏设置页可查看。音效由本项目程序合成，不包含采样自他人的音轨。

## 版本边界

单机收藏与成长为 V1 范围；账号、云存档、联网排行、商店发布、广告与内购均不是 V1 功能。详见 docs/KNOWN_ISSUES.md 区分未验证的目标设备体验与未来扩展。
