# 远岸钓记 1.2.0 · 两鱼真3D验收版

一个简体中文、竖屏、完全离线的 Godot 3D 钓鱼体验。本轮按用户确认限定为一个固定骨骼角色、鲤鱼与鳄雀鳝两种真实3D鱼、一处虚构管理型河湾试钓场，先验收动作、镜头、水面、起鱼与手机交互，再决定是否扩展。

既有44物种资料、6水域/12钓点数据和旧存档纪录保留；本版不是44鱼/12钓点全部3D化，也不把这些历史水域列为当前可玩的3D地点。三档装备、四种无限鱼饵、图鉴和收藏沿用原系统。

## 游玩

1. 从主页点击“开始钓鱼”，进入准备页，选择鲤鱼、鳄雀鳝或混合试钓目标，调整装备与鱼饵
2. 点击“进入钓点”后，才出现抛竿操作；长按右下角鱼竿蓄力，松手后播放完整骨骼抛竿动作
3. 观察浮漂；明显咬钩后提竿，按住收线，张力高时松手卸力
4. 成功后先播放鱼出水与起鱼镜头，再显示结算。钓获会先安全落盘，过场、暂停或返回不会重复计数
5. 出售或放生都保留历史数量，以及分别对应真实个体的最大长度/重量纪录
6. 行囊、鱼饵、图鉴和说明页支持手指上下滑动；拖动取消点击，轻点才执行操作

普通尺寸鱼的自动化控线验证约 12.6–24.5 秒；较大个体更难。鱼种稀有度与个体罕见大尺寸是不同维度。

中华鲟作为虚拟保护观察条目，只能放归，不提供出售。观察与放归同样保留累计数量和真实个体纪录；游戏互动不对应现实捕捞。

## 安装与更新

- 本轮目标设备：Android16、骁龙8 Elite的ARM64手机；最低系统声明API29不等于对所有旧手机作兼容/性能承诺
- 下载签名发行 APK，在手机允许对应下载应用“安装未知应用”后安装。具体系统设置位置依设备厂商而异
- 图形使用Mobile Vulkan，要求可用的Vulkan驱动，不静默降为OpenGL。帧率、发热与驱动表现须以目标手机实测为准
- 这是单机应用，不申请网络、账号、通讯录、定位、存储读取等权限；仅使用可关闭的 VIBRATE
- 覆盖更新必须保持相同包名、签名身份，并提升 versionCode；不要先卸载旧版本
- 本地存档在应用私有数据目录的 Godot user:// 下。系统普通文件浏览器通常不能直接访问
- 卸载、清除应用数据会丢失进度。本版没有云同步，不承诺跨安装保留
- 构建、静态检查、桌面、模拟器与真机验证严格分开，详见 docs/ACCEPTANCE.md 和 docs/ANDROID_TESTS.md

## 打开工程

使用官方 Godot 4.6.3 stable（7d41c59c4），导入 game/project.godot 后运行。Mobile Vulkan渲染，真实Node3D/Camera3D、网格、Skeleton3D和AnimationPlayer；无C#、WebView或后端。项目内包含所有运行素材、JSON、中文授权字体与音效。首次导入会重建 .godot 缓存，无需下载游戏内容。

## 3D与交互实现

角色、两种鱼和河湾环境均有原创可编辑Blender资产及GLB。抛竿、收线、起鱼和鱼体游动/挣扎使用骨骼动画，鱼线、水花、涟漪、材质和镜头使用Godot原生能力与项目代码；没有引入第三方绳索、水体或动画插件。开源方案的取舍记录在docs/OPEN_SOURCE_3D_EVALUATION.md。

主页、准备与钓鱼模式分开。既有25枚高清绘制图标继续用于透明图标加文字的界面；图鉴历史插画不冒充3D模型。详见docs/3D_UI_FLOW.md、docs/STAGE_3D.md和docs/TRIAL_SCOPE.md。

## 构建 Android

详见 docs/BUILD.md。匹配的官方模板、JDK、Android SDK 与 Gradle 精确版本记录在该文件。执行 tools/android_build.sh arm64。SDK 首次安装需自行接受其许可。签名通过环境变量指向独立的私钥与密码文件，源码不包含签名凭据。

## 自动化测试

从源码根目录执行（使用隔离数据目录，勿指向实际玩家存档）：

    HOME=/tmp/farshore-test-home XDG_DATA_HOME=/tmp/farshore-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/save_tests.gd
    HOME=/tmp/farshore-test-home XDG_DATA_HOME=/tmp/farshore-core-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/core_tests.gd

先创建上述临时目录。另有trial_fishery_tests.gd、touch_scroll_tests.gd、slice3d_tests.gd与ui_style_tests.gd；每项测试的隔离目录要求和最新结果见对应文档。测试源码不导出到发行APK。最终视觉、源代码和设备证据见docs/3D_ACCEPTANCE.md，不能以旧版计数替代本次复验。

## 文件结构

- game/scripts/：类型化 GDScript 模块
- game/scenes/main.tscn：原生 Control 场景入口
- game/data/fish_a.json 至 fish_d.json：44 物种的单一来源分片
- game/data/world.json：水域、钓点、装备与鱼饵
- game/assets/3d/：实际运行的角色、鱼、环境GLB及材质纹理
- game/assets/shaders3d/：水体、植被与环境材质
- game/assets/：图标、历史图鉴插画、音效与字体
- art_masters/3d/：可编辑的原创Blender模型、骨骼和动画
- tools/art3d/：原创几何、材质与动画的可复现制作脚本
- art_masters/：历史高清插画底稿，运行不依赖这些文件
- docs/：内容、来源、素材清单、架构、构建与验收记录
- spec/：原始开发需求
- tools/：构建脚本；工具二进制和下载缓存不进入源码包

## 资料与许可

鱼类分布和形态参考鱼类数据库与海洋研究机构，逐物种链接见 docs/FISH_A_SOURCES.md、FISH_B_SOURCES.md、FISH_C_SOURCES.md、FISH_D_SOURCES.md。出现倍率、尺寸锚点、重量立方缩放、时间/天气、难度与稀有度是游戏调校，不冒充实测科研关系，也不提供现实垂钓法规建议。

1.2.0的三维几何、角色/鱼材质、骨骼、动画和环境构建为本项目原创Blender/Godot制作；天空光照与码头木材使用Poly Haven的CC0素材（Greg Zaal、Rob Tuytel），并非本项目原创照片。来源、作者、原文件哈希与许可见docs/ASSETS_3D_ENVIRONMENT_CC0.json和game/data/THIRD_PARTY_ART.txt，原创模型记录见docs/ASSETS_3D_*.md。既有二维鱼类/场景插画及界面图标为内置图像生成工具逐资产生成，经开发者形态与透明边缘检查；完整提示词、资料、生成方式与审核记录见 docs/ASSETS_*.json。没有复用未获授权的外部照片。生成来源不构成独占权利或专业物种鉴定保证。中文字体使用 Noto Sans CJK（SIL OFL），详见 docs/FONT_LICENSE.txt。Godot 及第三方库许可在 game/data/GODOT_LICENSE.txt，游戏设置页可查看。音效由本项目程序合成，不包含采样自他人的音轨。

## 版本边界

本次严格止于两鱼3D验收，不未经用户确认继续扩展；账号、云存档、联网排行、商店发布、广告与内购均不是 V1 功能。详见 docs/KNOWN_ISSUES.md 区分未验证的目标设备体验与未来扩展。
