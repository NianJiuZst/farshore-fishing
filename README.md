# 远岸钓记 1.2.0-beta.2 · 观漂与控鱼

简体中文、竖屏、完全离线的 Godot 原生3D钓鱼游戏。当前实现44种独立骨骼鱼模型、一个固定钓手、六地区十二钓点、五款鱼竿、八类无限补给鱼饵，以及图鉴、收藏、成长与持久化个人纪录。

本版从大厅进入准备和钓鱼模式，包含人物抛竿、过肩/水面镜头、咬钩、控线搏鱼、鱼出水及起鱼展示。全部既有鱼种、地区和旧存档继续使用，不清空旧记录。源代码的实际验证范围与未完成设备验证必须以本次验收记录为准，不能把旧版结果或静态模型预览当作安卓实机通过。

## 游玩

1. 从大厅点击“开始钓鱼”，进入准备页，选择已解锁的水域/钓点，调整鱼竿与鱼饵
2. 点击“进入钓点”后，才出现抛竿操作；长按右下角鱼竿蓄力，松手后播放完整骨骼抛竿动作
3. 落水后镜头保持不变，收线按钮一直可用。观察鱼漂的试探轻点、持续下沉、送漂或走漂；按早了会空竿，过晚会脱口，没有咬钩弹字、按钮变亮或震动提醒
4. 在咬牢时按下，可以继续按住收线，观察竿梢、水纹与鱼的转向。冲刺前松手卸力，冲势放缓时收回距离；长时间松线会跑鱼，迎着冲势硬拉会断线
5. 成功后先播放鱼出水与起鱼镜头，再显示结算。钓获会先安全落盘，过场、暂停或返回不会重复计数
6. 出售或放生都保留历史数量，以及分别对应真实个体的最大长度/重量纪录
7. 行囊、鱼饵、旅行、图鉴和说明页支持手指上下滑动；拖动取消点击，轻点才执行操作
8. 未购买的鱼竿可临时试钓借用，实际控鱼参数和3D外观都会变化；借用不会扣钱或改写已拥有装备，重启后恢复已装备鱼竿

鱼有独立体力、距离与随机变化的冲刺/恢复节奏。巨物体力明显更强，需要更长的收放较量；高级竿提高容错，并不会自动化解所有冲刺。长期僵持会磨损鱼线，在明显受力警告后增加小概率断线风险。鱼种稀有度与个体罕见大尺寸是不同维度。

本版机制、策略对比和实际可复现时长，以 docs/FISHING_SKILL_BALANCE.md 与本版验收记录为准。旧版10–25秒基线不适用于当前机制。

中华鲟作为虚拟保护观察条目，只能放归，不提供出售。观察与放归同样保留累计数量和真实个体纪录；游戏互动不对应现实捕捞。

## 安装与更新

- 本轮目标设备：Android16、骁龙8 Elite的ARM64手机；最低系统声明API29不等于对所有旧手机作兼容/性能承诺
- 下载签名发行 APK，在手机允许对应下载应用“安装未知应用”后安装。具体系统设置位置依设备厂商而异
- 图形使用Mobile Vulkan，要求可用的Vulkan驱动，不静默降为OpenGL。帧率、发热与驱动表现须以目标手机实测为准
- 这是单机应用，不申请网络、账号、通讯录、定位、存储读取等权限；仅使用可关闭的 VIBRATE
- 覆盖更新必须保持相同包名、签名身份，并提升 versionCode；不要先卸载旧版本
- 本地存档在应用私有数据目录的 Godot user:// 下。系统普通文件浏览器通常不能直接访问
- 卸载、清除应用数据会丢失进度。本版没有云同步，不承诺跨安装保留
- 构建、静态检查、桌面、模拟器与真机验证严格分开，以本版 docs/3D_ACCEPTANCE.md、docs/ANDROID_3D_BUILD.md 及最终发布说明为准；docs/ACCEPTANCE.md 的旧版历史结果不替代本版验证

## 打开工程

使用官方 Godot 4.6.3 stable（7d41c59c4），导入 game/project.godot 后运行。Mobile Vulkan渲染，真实Node3D/Camera3D、网格、Skeleton3D和AnimationPlayer；无C#、WebView或后端。项目内包含所有运行素材、JSON、中文授权字体与音效。首次导入会重建 .godot 缓存，无需下载游戏内容。

## 3D与交互实现

角色与44种鱼提供原创可编辑Blender资产；六地区环境由项目几何生成代码构建，均以真实GLB运行。抛竿、收线、起鱼和鱼体游动/挣扎使用骨骼动画，鱼线、水花、涟漪、材质和镜头使用Godot原生能力与项目代码；没有引入第三方绳索、水体或动画插件。开源方案的取舍记录在docs/OPEN_SOURCE_3D_EVALUATION.md。

主页、准备与钓鱼模式分开。31枚实际生成的高清透明图标用于图标加文字的界面。鱼种详情和钓获页是独立3D视窗与骨骼动画；图鉴列表可使用原插画缩略图以便浏览。详见docs/3D_UI_FLOW.md、docs/STAGE_3D.md、docs/FISH_3D_PREVIEW.md和docs/3D_CATALOG_SCOPE.md。docs/TRIAL_SCOPE.md仅为早期两鱼里程碑的历史说明。

## 构建 Android

详见 docs/BUILD.md。匹配的官方模板、JDK、Android SDK 与 Gradle 精确版本记录在该文件。执行 tools/android_build.sh arm64。SDK 首次安装需自行接受其许可。签名通过环境变量指向独立的私钥与密码文件，源码不包含签名凭据。

## 自动化测试

从源码根目录执行（使用隔离数据目录，勿指向实际玩家存档）：

    HOME=/tmp/farshore-test-home XDG_DATA_HOME=/tmp/farshore-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/save_tests.gd
    HOME=/tmp/farshore-test-home XDG_DATA_HOME=/tmp/farshore-core-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/core_tests.gd

先创建上述临时目录。可用 `python3 tools/run_full_catalog_qa.py --output build/full-catalog-qa --render` 协调导入、逻辑/界面/3D测试、独立44模型二进制审计与可用的桌面Vulkan测试。源码测试包括真实全目录出鱼、动画连接、最小/最大鱼镜头、触控冲突、存档故障与重启；历史trial_fishery测试只验证旧适配器/记录兼容。每项测试的隔离目录要求和最新结果见对应文档。测试源码不导出到发行APK。最终视觉、源代码和设备证据见docs/3D_ACCEPTANCE.md，不能以旧版计数替代本次复验。

## 文件结构

- game/scripts/：类型化 GDScript 模块
- game/scenes/main.tscn：原生 Control 场景入口
- game/data/fish_a.json 至 fish_d.json：44 物种的单一来源分片
- game/data/world.json：水域、钓点、装备与鱼饵
- game/data/fish_3d.json：44种独立3D资源的严格清单，缺失资源会阻止进入钓鱼而不是替换成另一种鱼
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

1.2.0-beta.1的角色/鱼网格、材质、骨骼与动画为本项目原创Blender制作，环境由原创几何生成代码与Godot原生渲染组成；天空光照、码头木材与岩石表面使用Poly Haven的CC0素材（Greg Zaal、Rob Tuytel、Dario Barresi、Rico Cilliers），并非本项目原创照片。来源、作者、原文件哈希与许可见docs/ASSETS_3D_ENVIRONMENT_CC0.json和game/data/THIRD_PARTY_ART.txt，原创模型记录见docs/ASSETS_3D_*.md。既有二维鱼类/场景插画及界面图标为内置图像生成工具逐资产生成，经开发者形态与透明边缘检查；完整提示词、资料、生成方式与审核记录见 docs/ASSETS_*.json。没有复用未获授权的外部照片。生成来源不构成独占权利或专业物种鉴定保证。中文字体使用 Noto Sans CJK（SIL OFL），详见 docs/FONT_LICENSE.txt。Godot 及第三方库许可在 game/data/GODOT_LICENSE.txt，游戏设置页可查看。音效由本项目程序合成，不包含采样自他人的音轨。

## 版本边界

本次范围为既有44鱼、六地区十二钓点的观漂提竿和控鱼机制更新，不新增额外地区/鱼种或联网系统。账号、云存档、联网排行、商店发布、广告与内购均不在本版范围内。详见 docs/KNOWN_ISSUES.md 区分未验证的目标设备体验与未来扩展。
