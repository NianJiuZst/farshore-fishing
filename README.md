# 远岸钓记 1.2.0 · 读漂与提竿

> 当前工作区包含一轮尚未发布的画面、交互与存档优化，基于下方 1.2.0 正式版。详见 [本地优化说明](docs/LOCAL_OPTIMIZATION.md)。本轮没有更改安装身份或发布新 APK。

简体中文、竖屏、完全离线的 Godot 原生3D钓鱼游戏。当前实现44种独立骨骼鱼模型、一个固定钓手、六地区十二钓点、五款鱼竿、八类无限补给鱼饵，以及图鉴、收藏、成长与持久化个人纪录。

本版从大厅进入准备和钓鱼模式，包含人物抛竿、过肩/水面镜头、咬钩、控线搏鱼、鱼出水及起鱼展示；图鉴、详情、放大和钓获结算使用44种独立生成的高清写实鱼类插画。全部既有鱼种、地区和存档结构保留。本版沿用 beta2/beta3 的包名与签名，可覆盖更新并保留其本地存档；它仍与早期 org.farshore.fishing 应用分开。源代码的实际验证范围与未完成设备验证必须以本次验收记录为准，不能把旧版结果或静态模型预览当作安卓实机通过。

## 本次更新

- 鱼会接近、试探、含饵、带饵移动、吐饵和重新接近；提竿按钩饵是否仍在鱼嘴里判定，取消固定等待后必定上鱼的时间窗口
- 送漂、顿沉、定向横移和小幅持漂来自同一套线组受力；水波、短促试探和有效鱼讯有可观察的节奏差别，不能只等最大动作
- 重新制作分段3D浮漂，明确中性水线、彩色漂目、漂身、碳脚和穿线环；固定水面镜头贯穿观察过程，没有咬钩提示音、按钮变色或自动切镜
- 准备页和设置内新增“读漂与提竿”，说明水线、试探、含饵与吐饵；游戏简化实际钓组，不将某个漂相描述为现实中必中的口诀
- 44种鱼全部补充科属、学名、一般尺寸、带量法和来源范围的最大尺寸、分布、栖息地、食性、习性和自然史故事；自然资料、游戏尺寸设定与个人最长/最重纪录分别显示
- 详情支持自然资料、个人纪录、资料来源跳转；资料正文可离线阅读，点击来源才在外部浏览器打开原文
- 保留既有44种鱼、高清插画、六地区十二钓点、五款竿、八种饵、图鉴真实纪录和全部存档保护

角色使用 MakeHuman Community 的 CC0 真人比例基础网格、皮肤和服装，配合本项目的权重适配与钓鱼动作。本版完整验证范围见最终验收记录。beta3 的弹窗、整图点击图鉴、独立长度/重量纪录、滚动与返回路径继续保留。

## 游玩

1. 从大厅点击“开始钓鱼”，进入准备页，选择已解锁的水域/钓点，调整鱼竿与鱼饵
2. 点击“进入钓点”后，才出现抛竿操作；长按右下角鱼竿蓄力，松手后播放完整骨骼抛竿动作
3. 落水后镜头保持不变，收线按钮一直可用。先观察水波与中性水线，再看试探轻点、顿沉、送漂、持漂或横移；钩饵尚未被含住或已被吐出时提竿都会空竿，没有咬钩弹字、按钮变亮或震动提醒
4. 读到鱼讯时重新按下提竿，上鱼后可以继续按住收线；此前已经按住的旧手势不能自动提竿。观察竿梢、水纹与鱼的转向。冲刺前松手卸力，冲势放缓时收回距离；长时间松线会跑鱼，迎着冲势硬拉会断线
5. 成功后先播放鱼出水与起鱼镜头，再显示结算。钓获会先安全落盘，过场、暂停或返回不会重复计数
6. 出售或放生都保留历史数量，以及分别对应真实个体的最大长度/重量纪录
7. 行囊、鱼饵、旅行、图鉴和说明页支持手指上下滑动；拖动取消点击，轻点才执行操作
8. 未购买的鱼竿可临时试钓借用，实际控鱼参数和3D外观都会变化；借用不会扣钱或改写已拥有装备，重启后恢复已装备鱼竿

鱼有独立体力、距离与随机变化的冲刺/恢复节奏。巨物体力明显更强，需要更长的收放较量；高级竿提高容错，并不会自动化解所有冲刺。长期僵持会磨损鱼线，在明显受力警告后增加小概率断线风险。鱼种稀有度与个体罕见大尺寸是不同维度。

读漂研究与实现边界见 docs/FLOAT_BITE_RESEARCH.md。本版策略对比和实际可复现时长，以 docs/FLOAT_ENCOUNTER_VALIDATION.md、docs/FISHING_SKILL_BALANCE.md 与本版验收记录为准。旧版10–25秒基线不适用于当前机制。

中华鲟作为虚拟保护观察条目，只能放归，不提供出售。观察与放归同样保留累计数量和真实个体纪录；游戏互动不对应现实捕捞。

## 安装与更新

- 本轮目标设备：Android16、骁龙8 Elite的ARM64手机；最低系统声明API29不等于对所有旧手机作兼容/性能承诺
- 本轮正式版配置：包名 `org.farshore.fishing.preview`，versionCode `6`，版本 `1.2.0`，桌面名称“远岸钓记”。使用与 beta2/beta3 完全相同的签名，可覆盖更新这两个版本。早期 org.farshore.fishing 的旧签名不参与此更新
- 已安装 beta2/beta3 的用户直接覆盖安装并保留原存档。首次安装预览包则建立新存档；早期旧包仍保留，不要卸载旧应用
- 下载经本轮发布验收确认的签名 APK 后，在手机允许对应下载应用“安装未知应用”再安装。具体系统设置位置依设备厂商而异；本文中的配置和源码检查不代表发布包已构建或验收完成
- 图形使用Mobile Vulkan，要求可用的Vulkan驱动，不静默降为OpenGL。帧率、发热与驱动表现须以目标手机实测为准
- 这是单机应用，不申请网络、账号、通讯录、定位、存储读取等权限；仅使用可关闭的 VIBRATE
- 一般覆盖更新必须保持相同包名、签名身份，并提升 versionCode。当前 1.2.0 满足与 beta2/beta3 覆盖更新的条件，仍不自动访问早期旧包的私有存档
- 本地存档在应用私有数据目录的 Godot user:// 下。系统普通文件浏览器通常不能直接访问
- 卸载、清除应用数据会丢失进度。本版没有云同步，不承诺跨安装保留
- 构建、静态检查、桌面、模拟器与真机验证严格分开，以本版 docs/FORMAL_ACCEPTANCE.md、docs/FORMAL_ANDROID_BUILD.md 及最终发布说明为准；docs/ACCEPTANCE.md 的旧版历史结果不替代本版验证

## 打开工程

使用官方 Godot 4.6.3 stable（7d41c59c4），导入 game/project.godot 后运行。Mobile Vulkan渲染，真实Node3D/Camera3D、网格、Skeleton3D和AnimationPlayer；无C#、WebView或后端。项目内包含所有运行素材、JSON、中文授权字体与音效。首次导入会重建 .godot 缓存，无需下载游戏内容。

## 3D与交互实现

角色提供基于 MakeHuman/MPFB CC0 资产的可编辑 Blender 源文件，配套适配与钓鱼动画由本项目制作；44种鱼提供原创可编辑 Blender 资产。六地区环境由项目几何生成代码构建，均以真实GLB运行。抛竿、收线、起鱼和鱼体游动/挣扎使用骨骼动画，鱼线、水花、涟漪、材质和镜头使用Godot原生能力与项目代码；没有引入第三方绳索、水体或动画插件。开源方案的取舍记录在docs/OPEN_SOURCE_3D_EVALUATION.md。

主页、准备与钓鱼模式分开。31枚实际生成的高清透明图标用于图标加文字的界面。鱼的3D模型与骨骼动画用于实际水中游动、搏鱼、出水和起鱼。图鉴、收藏、详情、放大、待处理钓获及结算页全部使用原生静态写实插画控件，不是实际野生动物照片；结算尺按经审核的鱼吻与尾端定位，排除须的延伸。

启动时严格校验44鱼3D清单及44鱼写实插画清单；缺项、哈希或透明边界不符会阻止开始钓鱼，不替换成其他鱼。全部44张高清透明PNG保留1536–2172像素宽的母版，44张缩略图最大边为512像素。运行PNG与母版逐字节一致。详见docs/FISH_PHOTO_UI.md、docs/3D_UI_FLOW.md、docs/STAGE_3D.md和docs/3D_CATALOG_SCOPE.md。docs/FISH_3D_PREVIEW.md说明保留的历史3D预览组件；docs/TRIAL_SCOPE.md仅为早期两鱼里程碑的历史说明。

## 构建 Android

本正式版的预构建模板路线、冻结与隔离导出命令见 docs/FORMAL_ANDROID_BUILD.md；历史 Gradle 路线见 docs/BUILD.md。先校验独立源码归档，再从隔离副本导出，不能直接在唯一源码目录执行清理或打包。匹配的官方 Godot 模板、JDK 与 Android SDK 版本和命令均在构建文档中。SDK 首次安装需自行接受其许可。签名通过环境变量指向独立的私钥与密码文件，源码不包含签名凭据。

## 自动化测试

从源码根目录执行（使用隔离数据目录，勿指向实际玩家存档）：

    HOME=/tmp/farshore-test-home XDG_DATA_HOME=/tmp/farshore-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/save_tests.gd
    HOME=/tmp/farshore-test-home XDG_DATA_HOME=/tmp/farshore-core-test-user XDG_CACHE_HOME=/tmp/farshore-test-cache godot --headless --path game --script res://tests/core_tests.gd

先创建上述临时目录。可用 `python3 tools/run_full_catalog_qa.py --output build/full-catalog-qa --render` 协调导入、逻辑/界面/3D测试、独立44模型二进制审计与可用的桌面Vulkan测试。源码测试包括真实全目录出鱼、动画连接、最小/最大鱼镜头、触控冲突、存档故障与重启；历史trial_fishery测试只验证旧适配器/记录兼容。每项测试的隔离目录要求和最新结果见对应文档。测试源码不导出到发行APK。本版视觉、源代码和设备证据边界见docs/FORMAL_ACCEPTANCE.md，不能以旧版计数替代本次复验。

## 当前已核验范围

- 本版读漂机制矩阵：24,768场，6,273项断言与7项玩法门槛通过；另有独立种子与观察延迟检查。模拟控制器结果不代表所有玩家的成功率，完整方法和证据见 docs/FLOAT_ENCOUNTER_VALIDATION.md
- 写实插画专项：完整性/几何34/34；全部44鱼静态页面在720×1280和720×1584各1182/1182；选取7鱼的原生桌面Mobile Vulkan页面280/280，末次日志干净退出。证据见 docs/evidence/1.2.0-beta.2/fish-photoreal/
- 这些是机制、桌面与无窗口专项证据；合并版本的整体回归、Android打包和目标手机验收另行记录，不能由上述专项通过推定

## 文件结构

- game/scripts/：类型化 GDScript 模块
- game/scenes/main.tscn：原生 Control 场景入口
- game/data/fish_a.json 至 fish_d.json：44 物种的游戏定义分片，保留历史物种标识以兼容存档
- game/data/encyclopedia_a.json 至 encyclopedia_d.json：44物种的独立离线自然资料、最新学名显示、字段级来源与尺寸记录范围
- game/data/world.json：水域、钓点、装备与鱼饵
- game/data/fish_3d.json：44种独立3D资源的严格清单，缺失资源会阻止进入钓鱼而不是替换成另一种鱼
- game/data/fish_art.json：44种写实插画及缩略图的严格清单，绑定原PNG、导入像素、透明边界和解剖端点
- game/assets/3d/：实际运行的角色、鱼、环境GLB及材质纹理
- game/assets/shaders3d/：水体、植被与环境材质
- game/assets/fish/：44种当前写实插画及44张缩略图
- game/assets/：图标、音效、字体及其他运行素材
- art_masters/3d/：可编辑的原创Blender模型、骨骼和动画
- tools/art3d/：原创几何、材质与动画的可复现制作脚本
- art_masters/fish_photoreal_v2/：当前44鱼原始高清插画、运行副本、缩略图、完整提示词、修订、资料来源和验证记录
- art_masters/：其他历史高清插画底稿，运行不依赖这些文件
- docs/：内容、来源、素材清单、架构、构建与验收记录
- spec/：原始开发需求
- tools/：构建脚本；工具二进制和下载缓存不进入源码包

## 资料与许可

图鉴自然资料的逐字段来源、分类差异和原始研究故事见 docs/ENCYCLOPEDIA_A_SOURCES.md、docs/ENCYCLOPEDIA_B_SOURCES.md、docs/ENCYCLOPEDIA_CD_SOURCES.md，独立交叉检查及其范围见 docs/ENCYCLOPEDIA_INDEPENDENT_REVIEW.md。常见尺寸可能来自特定地区或全年龄样本，不把资料库常见长度冒充全球成鱼平均值；缺少可靠极值时明确留空。

既有鱼类分布和形态参考鱼类数据库与海洋研究机构，逐物种链接见 docs/FISH_A_SOURCES.md、FISH_B_SOURCES.md、FISH_C_SOURCES.md、FISH_D_SOURCES.md。出现倍率、尺寸锚点、重量立方缩放、时间/天气、难度与稀有度是游戏调校，不冒充实测科研关系，也不提供现实垂钓法规建议。

正式版人物基于 MakeHuman Community 的 CC0 图形资产，官方来源、逐文件哈希、工具/资产许可区别及重建步骤见 docs/ASSETS_3D_ANGLER_LICENSES.md、docs/ASSETS_3D_ANGLER_PROVENANCE.json。

1.2.0-beta.1的角色/鱼网格、材质、骨骼与动画为本项目原创Blender制作，环境由原创几何生成代码与Godot原生渲染组成；天空光照、码头木材与岩石表面使用Poly Haven的CC0素材（Greg Zaal、Rob Tuytel、Dario Barresi、Rico Cilliers），并非本项目原创照片。来源、作者、原文件哈希与许可见docs/ASSETS_3D_ENVIRONMENT_CC0.json和game/data/THIRD_PARTY_ART.txt，原创模型记录见docs/ASSETS_3D_*.md。当前44种写实鱼类插画、既有二维场景插画及界面图标均为内置图像生成工具逐资产生成，经开发者形态与透明边缘检查。写实鱼类插画不是野生动物实拍照片；完整提示词、解剖修订、资料和审核记录见 art_masters/fish_photoreal_v2/，其他素材记录见 docs/ASSETS_*.json。没有复用未获授权的外部照片。生成来源不构成独占权利或专业物种鉴定保证。中文字体使用 Noto Sans CJK（SIL OFL），详见 docs/FONT_LICENSE.txt。Godot 及第三方库许可在 game/data/GODOT_LICENSE.txt，游戏设置页可查看。音效由本项目程序合成，不包含采样自他人的音轨。

## 版本边界

本次范围为既有44鱼、六地区十二钓点的读漂提竿交互、精细3D浮漂、真人比例人物替换与44物种的详细自然资料，不新增额外地区/鱼种或联网系统。账号、云存档、联网排行、商店发布、广告与内购均不在本版范围内。详见 docs/KNOWN_ISSUES.md 区分未验证的目标设备体验与未来扩展。
