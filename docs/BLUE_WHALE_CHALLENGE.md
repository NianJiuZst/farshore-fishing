# 蓝鲸「鲸影共鸣」挑战

在 **太平洋 → 远洋蓝水航线** 的大厅、准备页或空闲钓点点击「鲸影共鸣」，阅读说明后开始。挑战独立于普通抛竿、鱼饵和钓获结算；进行中的普通钓竿与未处理钓获会阻止进入。每次挑战可暂停、取消或失败后重新尝试。

## 可以完成的三阶段操作

1. **连起三道光环**：按住提高光脉冲，松手降低；保持在 42–66% 绿带，三次各累计 1.2 秒。
2. **跟随潮流**：按住左、右控制亮点方向，追随移动绿带，累计同步 10 秒。
3. **能量张力共鸣**：按住收紧、松手放松，保持在 38–65% 绿带，累计共鸣 8 秒。极端张力持续 2.2 秒会失稳。

每阶段均显示目标绿带、进度与剩余时间。时限分别为 30、28、24 秒，空置输入不能完成。可观察状态的自动控制测试用时 **25.4 秒**；这不是普通玩家操作时间承诺。后台和系统返回会先暂停，恢复不会留下按住状态。

## 专用 3D 巨物展示

独立舞台将蓝鲸模型的 1 米制作坐标映射到 **26 米世界尺度**，以 5.6 米船作比例参照；专用镜头包含全身、动画胸鳍、水平尾叶、外侧光环和船。蓝鲸播放专用上下摆尾游动动画。能量线连接头部前方独立光环，未连接嘴部或钩刺身体。成功后线消退，蓝鲸继续在水中游动，镜头展示全身；舞台不调用普通鱼的起鱼或落地动画。

## 独立纪录与 1.3.0 存档

保留原 schema 2，并追加 `whale_challenge` 扩展，保存完成次数、首次、最近、最快用时与图鉴解锁。既有 74 个物种 ID、鱼获计数、尺寸纪录、货币、装备、区域解锁、收藏、设置和待处理鱼获保持原值。鲸类不进入出售库存，不获得鱼获奖励，不计入 **110 种鱼类** 的发现与钓获数量。旧存档不会重新得到新安装时的 1500 金币与六区域补助。

鲸类结算使用原有已校验主存档/备份事务。保存失败时保留完成纪录与会话，显示重试保存或明确放弃；离开和重新挑战不会悄悄丢失未保存纪录。重复「开始」回调在 LINK/CURRENT/RESONANCE/PAUSED 四种活动状态都先返回，不改变保存会话。

## 真实资料与幻想边界

蓝鲸 `Balaenoptera musculus` 是哺乳动物中的须鲸，主要滤食磷虾；图鉴明确 `animal_kind=mammal`、`fishing_enabled=false`、`encounter_type=fantasy_challenge`。普通鱼候选抽样与鱼类列表会排除它。图鉴资料来自 [NOAA 蓝鲸物种页](https://www.fisheries.noaa.gov/species/blue-whale) 与 [NOAA 海洋动物观察指南](https://www.fisheries.noaa.gov/topic/marine-life-viewing-guidelines)，逐字段记录来源。

资料标注 NOAA 列示的保护身份、缠网与船撞威胁，以及现实观察应保持距离、不喂食、不触摸或追逐。26 米体长、近距离船侧画面、展示水层和三阶段能量连线均为游戏改编；它们不构成真实鲸类捕捞或接近指导。

## 可重复验证

使用完整 Godot 4.6.3 app bundle：

```sh
python3 tools/run_blue_whale_tests.py \
  --godot /absolute/path/Godot.app/Contents/MacOS/Godot \
  --output /absolute/path/audit/blue-whale/final-tests

python3 tools/run_blue_whale_ui.py \
  --godot /absolute/path/Godot.app/Contents/MacOS/Godot \
  --capture-dir /absolute/path/audit/blue-whale/frames
```

两个运行器将完整项目复制到 `/tmp` 临时目录，从进程继承环境移除 home 路径并在临时项目内运行，不修改共享源码或全局环境。所有存档测试另外明确注入 `/tmp/farshore-whale-*` 目录；没有初始化真实玩家的 SaveStore。原生截图脚本完全不引用 SaveStore。

2026-10-04 本机结果：

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 状态机、1.3.0 事务、备份、事实资料、实模型、4 种镜头比例 | 89/89 | `audit/blue-whale/final-tests/challenge.stdout.log` |
| 真实触控按钮、8px 标尺、暂停、结果与重试布局 | 51/51 | `audit/blue-whale/final-tests/ui.stdout.log` |
| 生产 Main 全 111 动物资产严格门槛、重复开始、保存失败、独立图鉴与返回 | 53/53 | `audit/blue-whale/final-tests/main.stdout.log` |
| 原生 Mobile/Vulkan 与七个阶段截图 | 65/65 | `audit/blue-whale/frames/run.json` 与 `01-link.png` 至 `07-failed.png` |

原生证据是 Apple M5、Vulkan 1.2.283、Forward Mobile，窗口 720×1280，使用本任务批准的原生进程执行。没有把 macOS 渲染结果称为 Android 真机性能测试。sandbox headless 启动有 `get_system_ca_certificates` macOS 平台诊断；原生运行无该诊断，但相对隔离 `user://` 会报告无法创建 shader cache。上述日志保留这些诊断，实际 GDScript 检查与截图均通过。
