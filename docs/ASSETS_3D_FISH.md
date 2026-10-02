# 3D 鱼类验收切片 · Common carp / Alligator gar

制作及核查日期：2026-10-02。Blender 4.3.2 原创制作，Godot 4.6.3 导入验证。

## 交付范围

本文件记录首轮两种已完成的三维鱼：`common_carp`（鲤鱼 / Cyprinus carpio）与 `alligator_gar`（鳄雀鳝 / Atractosteus spatula）。用户随后明确要求扩展全部44种，当前计划见 `FISH_3D_FAMILY_PLAN.md`，首批特型鱼见 `ASSETS_3D_SPECIALISTS.md`。这两个已验收资产保留，既有二维鱼图不被覆盖；首轮完成不代表44种完成。

- 母稿：`art_masters/3d/common_carp.blend`、`art_masters/3d/alligator_gar.blend`
- 运行模型：`game/assets/3d/common_carp.glb`、`game/assets/3d/alligator_gar.glb`
- 可重复制作脚本：`tools/art3d/build_fish.py`
- 实际渲染、动作分格与核查：`ownbuild/fish3d-review/`
- 校验清单及逐文件 SHA-256：`ownbuild/fish3d-review/asset_manifest.json`

两种模型均为围绕完整横截面构建的闭合体积鱼体、真实厚度的鳍膜及立体鳍条、双侧眼、嘴部和鳃盖结构；不是贴图裁切平面、鱼图 billboard 或仅旋转刚体。鱼体表面采用专属 UV、原创基色/法线/粗糙度贴图。所有贴图内嵌 GLB 并打包到 `.blend`，没有外部纹理路径依赖。

## 物种与美术

### 鲤鱼

- 厚实的背腹弧线、稍扁的侧体、圆润头颊
- 黄铜褐至橄榄背色、较浅腹色、大型弧边圆鳞、轻微不规则色差
- 长基底背鳍、叉状尾、成对胸腹鳍、独立臀鳍
- 小型下位可动口、两对短口须、小型贴合眼窝的眼睛
- 减弱早期预览中的金属刻槽感、白色粗眼圈和粗鳃缘；鳍外缘改为连续圆润曲线

### 鳄雀鳝

- 细长但有真实厚度的近圆筒鱼体，橄榄灰背、浅腹和菱形硬鳞
- 长而宽扁的吻部，在俯视图明确显示宽度，避免细针状长吻雀鳝轮廓
- 独立立体下颌、细小牙列、双眼及鼻孔
- 明显后移的背鳍/臀鳍、圆润略不对称的短歪尾（上部稍长），鳍膜有深色斑点
- 这是自然取向的游戏风格化造型，不是鳞片/鳍条计数鉴定模型

形态参考包括本项目 `docs/FISH_A_SOURCES.md`、`docs/FISH_C_SOURCES.md` 与现有两张物种插画的实际像素；只用于识别与比例观察。未把二维鱼图投射为成品纹理，也未下载/嵌入第三方照片。

事实核查的原始来源：

- [FishBase: Cyprinus carpio](https://www.fishbase.se/summary/Cyprinus-carpio.html)
- [US Fish & Wildlife Service: Alligator gar](https://www.fws.gov/species/alligator-gar-atractosteus-spatula)
- [Florida Fish & Wildlife Conservation Commission: Alligator gar](https://myfwc.com/wildlifehabitats/profiles/freshwater/alligator-gar/)

## 坐标、尺寸与接入契约

| 项目 | 约定 |
|---|---|
| Blender 母稿 | 鼻朝 +X，上方 +Z，侧宽沿 ±Y |
| GLB / Godot | 鼻朝 +X，上方 +Y，侧宽沿 ±Z |
| 原点 | 身体中线、鼻尾总包围范围的 X 中心；没有漂移根骨 |
| 单位 | 米；两种鱼静置鼻尾总长均精确归一化为 1.0 m |
| 缩放 | 游戏按标本长度统一缩放根节点，不改单轴比例 |
| 世界位移 | 由关卡控制游动/跃出轨迹，动画本身无向前或向上根位移 |
| 循环 | 关键帧首尾一致；GLTF 不编码播放循环策略，Godot 端须设 `Animation.LOOP_LINEAR` |

Godot 导入静态 AABB（包括全部鳍）：鲤鱼 `(1.000, 0.524, 0.333)` m；鳄雀鳝 `(1.000, 0.249, 0.228)` m。它们不是鱼体净厚度。

## 网格、材质与骨骼

| 模型 | 顶点（Blender） | 三角面 | 蒙皮网格 / 材质面 | 骨骼 |
|---|---:|---:|---:|---:|
| common_carp | 14,581 | 28,334 | 9 / 9 | 16 |
| alligator_gar | 15,188 | 29,408 | 9 / 9 | 16 |

主体/鳍膜均有基色、切线空间法线、粗糙度贴图：鱼体 2048×1024，鳍膜 1024×512。其余为眼、细鳍条、口/鳃缘和口腔等 PBR 材质。几何零件按材质合并，避免每根鳍条一个 draw call。没有因低端手机预算而减少物种特征或仅保留单面轮廓。

16 骨骼名称：`root`、`head`、`spine_front`、`spine_mid`、`spine_rear`、`tail`、`caudal`、`dorsal`、`anal`、`pectoral_L/R`、`pelvic_L/R`、`gill_L/R`、`jaw`。

逐顶点实际蒙皮，最多3个有效影响；鱼体有连续脊柱权重，尾部是延迟传播的侧向波，鳍根与其所在鱼体一致加权，鳍尖渐进弯动。鲤鱼下颌区域也参与下颌蒙皮。不是把整条鱼当一个骨骼刚体摆动。

## 四个烘焙动作

30 fps 采样，名称在 Godot 中原样保留：

| Clip | 时长 | 内容 |
|---|---:|---|
| `swim` | 2.0 s | 头至尾延迟传播的小幅侧摆，胸腹鳍与鳍膜轻动 |
| `struggle` | 1.2 s | 更强侧弯和尾踢，轻微竖向弯曲、张口与鳍运动 |
| `breach` | 1.4 s | 循环身体踢动；真正的出水弧线/入水由关卡位移提供 |
| `landed` | 3.0 s | 缓慢鳃盖/嘴部呼吸及鳍轻动，弱化身体摆动 |

## 已完成验证

- 实际 Cycles 渲染：左右可读的立体 hero、侧面、俯视、正面、背面；俯视能直接证明鱼体与宽吻具有体积
- 四段动作各四个相位的实际变形渲染；动画对比图为渲染图拼版，不是概念画
- Blender 对所有蒙皮顶点测量：权重和范围 `0.99990–1.00000`，最大3影响；四个动作均有非零实际网格变形，循环首尾误差小于 `1e-5 m`
- 鲤鱼游动相位最大蒙皮位移约 0.094 m，挣扎约 0.339 m；鳄雀鳝分别约 0.093 m、0.327 m
- 独立 Godot 4.6.3 项目读取最终两个 GLB：各1个 Skeleton3D、1个 AnimationPlayer、16骨骼、9个蒙皮网格，四个动作均驱动全部15个非根骨骼；无验证失败
- Godot 读到的时长分别为 2.0 / 1.2 / 1.4 / 3.0 s；静态鼻尾长度均 1.0 m
- 核查文件：`blender_skinning_report.json`、`godot_import_report.json`，及可重复执行的 `verify_blender.py`、`import_check/check.gd`

这里的验证不替代整合关卡的水下灯光、游戏内镜头和 Android 真机帧率验收。那些由主工程整合测试负责。

## 重建

```sh
blender -b --python tools/art3d/build_fish.py -- --species all
# 仅重建母稿与运行 GLB：
blender -b --python tools/art3d/build_fish.py -- --species all --no-render
# 用最终母稿重新输出多角度/动作核查图：
blender -b --python tools/art3d/build_fish.py -- --species all --review-existing
blender -b --python ownbuild/fish3d-review/verify_blender.py
# 独立项目复现 Blender + Godot 验证：
bash ownbuild/fish3d-review/run_checks.sh
```

授权说明：模型拓扑、UV、程序化纹理、骨骼、权重、动作和脚本为本项目原创制作。事实资料不作为第三方图片或模型再分发许可。未购买资产、使用未批准的付费接口或新建账号。

## 全目录验收期间的接触修复
后续持久化鳍根检查发现首版手工定位的鳍根存在深埋/离体误差，不能仅凭静态正面图判断。已先验证原版GLB及母稿备份的SHA-256一致，再用真实鱼体曲面采样与尾柄端面重建鳍根；鱼体轮廓、材质颜色、三角面数量及原有四动作保持。鲤鱼/鳄雀鳝在静态及四动作各9相位的最大接触距离分别为2.14/2.19毫米（1米归一尺度），低于4毫米网格密度/轻微嵌入容差。最终报告位于ownbuild/fish3d-catalog/{common_carp,alligator_gar}/validation.json。
