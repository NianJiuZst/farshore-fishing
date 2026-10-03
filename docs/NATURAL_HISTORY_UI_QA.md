# 44种鱼自然图鉴：内容与原生界面验证

验证日期：2026-10-03 UTC。此报告覆盖自然资料模块、图鉴界面和相关导航；不替代完整发行回归、Android实机测试或独立事实审核。

## 结果

| 检查 | 720×1280 | 720×1584 |
|---|---:|---:|
| 最终 `natural_history_tests.gd`，真实桌面 Mobile/Vulkan | 969/969 | 969/969 |
| 既有 `fish_notebook_ui_tests.gd`，隔离 headless | 313/313 | 313/313 |
| 最终原生截图 | 10张 | 10张 |
| 最终运行脚本错误、资源滞留警告 | 0 | 0 |

最终原生运行使用 Godot 4.6.3 stable、Mobile、Vulkan 1.4.305、Mesa llvmpipe。截图来自真实生产 Main 的 Viewport framebuffer，没有重绘、拼接、浏览器替代界面或字体排版模拟。为专注图鉴，测试关闭根 Viewport 的3D绘制并停止测试环境中不需要的音频播放；所有图鉴控件、图片、文本、滚动和交互仍使用生产实现。这是桌面软件渲染，不证明Android手机的帧率、发热、音频、外部浏览器或实机表现。

测试和截图使用隔离的 HOME、XDG 目录及 SaveStore，拒绝非隔离环境。截图中的钓获是明确标注的测试样本：经生产 SaveStore 正常结算、放生，尺寸和时间由测试固定，不是玩家存档，也不宣称来自正常实机钓鱼过程。

## 内容契约

- 四份JSON均为版本1结构；物种ID覆盖44种且无重复、遗漏或目录外条目
- 当前接受学名与属名一致；中英文科名、属名、常见体型、分布、栖息环境、习性、食性和故事均可离线读取
- 所有自然资料字段都引用同一条目中定义的来源；每种至少两个来源，来源元数据完整
- 自然最大尺寸必须是正的有限数值，或者明确使用 null；长度量法限定为 TL、FL、SL 或未注明，缺失值不会转成0
- 负例覆盖缺失/错误ID、学名与属名冲突、九类字段缺少或引用不存在的来源、重复来源ID、危险URL、零/负数/字符串/无穷/NaN尺寸、错误长度量法以及空/非文本纪录范围标签
- 资料副本修改不会反向改写内存中的原始条目；未提供条目时的学名回退可用
- 实际44种详情页逐项核对接受学名、拉丁科属、六个完整自然段、可见引用编号及全部原始来源按钮绑定

初次检查发现 `validate_entry` 未单独拒绝缺失物种ID。生产模块已补充合法字符串ID验证；对应负例在最终运行通过。旧图鉴测试仅更新接受学名、已核实新资料介绍和“游戏内寻鱼”标题三类预期，原有钓获数量、独立纪录、整块鱼图触摸及拖动检查保留。

## 界面与数据隔离

- 44种鱼的个人钓获汇总均能完整出现在首屏
- 未发现：累计0条，个人最长/最重显示破折号，不产生收藏或发现记录
- 一条鲤鱼样本：60.0cm、1.20kg
- 三条鲤鱼样本：60.0cm/1.20kg、50.0cm/1.70kg、45.0cm/900g；首屏显示3条、最长60.0cm、最重1.70kg
- 最长、最重、首次、最近保留各自完整原始快照；最长鱼没有被拼接成“60cm且1.70kg”的虚构个体
- 自然资料的129cm/40.1kg与游戏尺寸设定18–90cm、个人纪录分区和措辞清楚，彼此不覆盖
- 阅读44种资料、跳转、放大图片和返回均不改变玩家钓获统计
- 中华鲟在详情、列表、放大图及钓获展示中使用 Acipenser sinensis；旧名 Sinosturio sinensis 仍能搜索到同一物种。黑尾海鲷的当前/旧拼写也覆盖相同四个展示面和搜索路径
- 南方鲇的物种长度和体重最大值均显示“未见可靠值”；143cm、22.8kg明确属于已报道标本，不冒充物种最大纪录，个人累计仍为0

## 实际输入与浏览器安全

- 真实 Viewport ScreenTouch 验证自然资料、个人纪录、资料来源三条跳转、放大图和收藏中的鱼种进入操作
- 返回图鉴恢复来源列表及原滚动位置；从收藏进入后返回收藏；图片放大返回正确鱼种
- 所有来源按钮先核对原始 `pressed` 连接确实绑定 Main 的受保护方法及该来源URL，然后仅对选中的测试按钮临时断开原连接并接入记录器
- 真实来源按钮点击只记录一次正确URL；垂直划动和水平拖动都不会触发额外打开动作
- 非HTTPS、带凭据、端口、控制字符、反斜线等URL负例被拒绝；实际调用一个无效 file URL 只出现界面提示，不打开程序或浏览器
- 来源按钮保留原生焦点；向实际控件树传递失焦、进入后台、重新聚焦和恢复通知后，当前资料页、滚动位置、独立钓获记录保持，钓鱼会话始终暂停，不会再次触发来源动作
- 整套自动测试从未打开外部浏览器，也未更改网络权限。联网后目标网站实际加载效果不在这套UI测试范围内

## 原生截图证据

正式保留的验证目录（日志及每组 evidence.json 同时保留）：

- [final-portrait/](evidence/1.2.0/natural-history/final-portrait/)，720×1280
- [final-tall/](evidence/1.2.0/natural-history/final-tall/)，720×1584

两组均包含以下10个实际屏幕：

| 文件 | 内容 |
|---|---|
| `01_carp_unknown_zero.png` | 鲤鱼未发现，0条及空个人纪录 |
| `02_carp_one_fixture_catch.png` | 一条测试钓获的首屏 |
| `03_carp_three_fixture_catches.png` | 三条测试钓获、独立最大纪录的首屏 |
| `04_carp_taxonomy_size.png` | 科属、常见体型、自然纪录尺寸及出处 |
| `05_carp_habits_diet_story.png` | 生活习性、食性、故事和游戏内寻鱼分界 |
| `06_carp_personal_records.png` | 独立最长/最重、首次/最近及水域计数 |
| `07_carp_sources.png` | 离线/外部浏览器提示与来源按钮 |
| `08_southern_catfish_unknown_maxima.png` | 南方鲇未知物种最大值与标本例子 |
| `09_sturgeon_current_name_zero_catch.png` | 中华鲟当前接受学名，个人0条 |
| `10_sturgeon_taxonomy_size.png` | 中华鲟科属、分类说明、NOAA纪录范围标签 |

上述两组共20张已逐类目视检查。自然段和来源标题正常换行；没有横向截字、内容互相覆盖或首屏个人汇总被挤出的问题。页面底部裁切表示正常可滚动内容，不是删去资料。

每组 `evidence.json` 包含实际渲染器、窗口与布局尺寸、检查结果、截图状态和生产模块、四份资料文件、测试脚本的SHA256。`fixture_total_catch_count` 表示隔离存档总钓获数；`selected_species_catch_count` 表示当前鱼种钓获数，因此鲤鱼样本建立后中华鲟和南方鲇仍明确为0。

初次 `build/natural-history-ui/portrait/`、`portrait-verified/`、`tall/` 证据保留在本次工作目录。早期720×1280运行的唯一退出警告定位到Dummy音频驱动残留的 water.wav 播放资源；测试在初始化时停止并清除不需要的环境音后，最终两组退出干净，没有修改生产音频。最终20张PNG与初次对应PNG逐文件SHA256完全相同，已经提供的初次预览画面未被替换。旧证据仅按要求更正钓获计数字段名称，保留原运行代码哈希。最终两份verbose日志各有六条Mesa将RGB8纹理转为RGBA8的格式兼容提示；这不属于脚本错误或资源滞留，目视检查及像素一致性验证均通过。

## 复现

Headless需要隔离目录（示例使用新的临时目录）：

```sh
qa_root=$(mktemp -d /tmp/farshore-natural-qa-XXXXXX)
mkdir -p "$qa_root/home" "$qa_root/data" "$qa_root/cache"
HOME="$qa_root/home" XDG_DATA_HOME="$qa_root/data" XDG_CACHE_HOME="$qa_root/cache" \
  godot --headless --path game --script res://tests/natural_history_tests.gd
```

原生截图使用既有隔离渲染启动器；输出目录必须不存在：

```sh
python3 tools/render_godot.py --timeout 300 -- \
  --path game --script res://tests/natural_history_tests.gd -- \
  --output=/absolute/new/output/directory
```

在用户参数中加入 `--tall` 运行720×1584。完整发行回归由主构建流程继续执行；本报告不涉及打包、签名或上传。
