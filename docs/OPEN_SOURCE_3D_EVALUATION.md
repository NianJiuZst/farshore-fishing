# 3D 钓鱼切片：开源复用评估

核查日期：2026-10-02。目标：Godot 4.6.3、Android 16 / ARM64，当前工程采用 GL Compatibility。本文是只读选型记录；没有下载安装、执行或集成下列第三方库，也没有修改运行代码。没有 Snapdragon 8 Elite 真机性能结果。

## 结论

首个切片优先使用现成的 Godot / Blender 原生能力：Blender 制作与绑定、GLB 导出、Godot `Skeleton3D` + `AnimationPlayer` 播放抛竿／持竿／收线动作，必要时用原生 `TwoBoneIK3D` 修正握竿位置。水面和细鱼线采用小型专用实现。开源项目有参考价值，但这次没有发现已证实可在本工程 Godot 4.6.3 + Android 16 + Compatibility 直接投入使用、无需适配的完整方案。

用户于 2026-10-02 明确选择 Godot 原生系统，后续停止第三方选型；原生方案已获采用授权。授权与选型不等于已经完成集成，实际功能和运行验证由实现阶段记录。Godot 为 MIT 授权，现有发行许可文件 `game/data/GODOT_LICENSE.txt` 继续保留。

## 原生基线

- Godot 推荐使用 glTF/GLB 交换带动画的 3D 资产；直接导入 `.blend` 实际仍会调用 Blender 转成 glTF。建议保留 Blender 源稿并在构建中使用预导出的 GLB，避免让 Android 构建环境依赖 Blender。OBJ 不携带骨骼蒙皮和动画。[Godot 4.6 格式说明](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)
- Blender 的 glTF 导出支持骨骼蒙皮、关键帧与形态键。模型生成工具只能提供网格时，不能据此声称获得可动画的绑定角色；必须另查骨骼、权重与动作。Blender 是制作工具，不是要打包进 APK 的运行依赖。[Blender 官方 glTF 手册](https://docs.blender.org/manual/en/3.0/addons/import_export/scene_gltf2.html?highlight=gltf)
- `AnimationPlayer` 适合有明确节奏的动作与跨动作混合；`Tween` 可用于短促浮漂、相机与 UI 反馈。不要仅凭所有节点都在移动就称为完整骨骼动画。[AnimationPlayer](https://docs.godotengine.org/en/4.6/classes/class_animationplayer.html)
- Godot 4.6 已提供 `TwoBoneIK3D`，适合有极向目标的上臂／前臂链；旧 `SkeletonIK3D` 标为弃用。角色动作先靠正确的绑定和动画，IK 仅修正接触，不引入另一套完整角色控制库。[TwoBoneIK3D](https://docs.godotengine.org/en/4.6/classes/class_twoboneik3d.html) · [SkeletonIK3D 状态](https://docs.godotengine.org/en/4.6/classes/class_skeletonik3d.html)
- 一根可视鱼线可用小型 `ImmediateMesh` 或 `ArrayMesh` 生成。先做明确端点、抛投弧线、下垂和张力对应的曲率；建议预算约 16–32 个采样点，而非大量刚体关节。这个预算是实现建议，不是基准测试结果。`ImmediateMesh` 的官方适用范围就是简单、经常变化的几何。[ImmediateMesh](https://docs.godotengine.org/en/4.6/classes/class_immediatemesh.html)

## 水面必须遵守的渲染边界

Godot 4.6 的内置 SSR 只属于 Forward+；Compatibility 和 Mobile 都没有。两者都有反射探针，分别最多每网格 2／8 个；Compatibility 没有 compute shader，Mobile 虽支持也不能因此推定适合手机的预算。它们均可读取屏幕／深度纹理，但没有 Forward+ 的法线／粗糙度缓冲。[4.6 渲染器对照](https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html)

建议当前用小型 spatial shader：低幅度波动、移动法线或解析法线、掠射角高光、天空／有限探针反射，钩落水与鱼挣扎触发少量有生命周期的圆形涟漪。涟漪可由网格环或局部着色参数产生，不必引入全水域流体求解。先限制透明覆盖面积、采样数和网格密度。反射探针不是实时平面镜，不应承诺准确反射每一次鱼跃。[反射探针说明](https://docs.godotengine.org/en/4.6/tutorials/3d/global_illumination/reflection_probes.html)

深度重建要区分 OpenGL 与 RenderingDevice 的 NDC／深度约定。把 Vulkan 水 shader 原封不动搬到 Compatibility，常出现深度、泡沫与折射错误。[官方深度重建说明](https://docs.godotengine.org/en/4.6/tutorials/shaders/advanced_postprocessing.html)

## 三个候选与取舍

### 1. Halyard：后续完整绳索／船舶玩法候选，当前暂缓

[源码](https://github.com/mikest/halyard) · [MIT 许可](https://github.com/mikest/halyard/blob/main/LICENSE.md) · [平台扩展声明](https://github.com/mikest/halyard/blob/main/halyard.gdextension)

- 仓库声明面向 Godot 4.5+，含 Verlet 绳索、动态长度、锚点、刚体张力反馈、网格生成／LOD、浮力；适合后续真的需要绳索碰撞、船体浮力的玩法
- 是 C++ GDExtension，依赖 godot-cpp 与 SCons／CMake 构建链。扩展配置列出 Android ARM64 debug／release 映射，但这不证明对应二进制可用、可加载或满足本项目性能目标
- README 提醒碰撞限制：物体对胶囊链绳索的碰撞限定 GodotPhysics3D，Jolt 有额外 caveat。不能把该系统当作跨物理后端完全一致的钓线解法
- 维护可见性：仓库可访问、列有测试与开发路线、展示 146 次提交；本次无法取得可靠的最后提交日期，因此不宣称持续活跃维护或已覆盖 4.6.3
- 成本判断：对一根装饰性细鱼线引入 native ABI、Android 导出与物理行为验证，收益不够；若玩法升级到真实绳索，再隔离评估

### 2. Verlet Rope for Godot 4（GDScript 版）：算法参考，当前不直接采用

[源码](https://github.com/sanyabeast/verlet_rope_4_gd) · [脚本](https://github.com/sanyabeast/verlet_rope_4_gd/blob/master/verlet_rope.gd) · [MIT 许可](https://github.com/sanyabeast/verlet_rope_4_gd/blob/master/LICENSE)

- 由 C# 版移植为纯 GDScript，基于 `MeshInstance3D` / `ImmediateMesh`，支持两端固定及末端物体位置／旋转；没有该实现本身的 .NET 或 native ABI 依赖
- 源码默认 10 个模拟点、60 Hz、2 次约束迭代，碰撞／更多点会增加 CPU 工作；这些是配置默认值，不是实测性能
- 静态阅读发现风险：`get_rope_collisions()` 以 `RopeCollisionType` 枚举对象参与比较，`collide_rope()` 同样匹配枚举对象，而导出的选择属性是 `rope_collision_type`。这是应先测试／修复的疑点，不是通过运行确认的缺陷
- 仓库声称 Godot 4、展示 28 次提交，但没有证实 4.6.3／Android 16 的验证矩阵，最后提交日期本次未核实。不要当成免维护的即插即用库
- 取舍：可读其绳索原理；本切片自写少量可控几何更易核验，不复用可疑碰撞分支

### 3. GodotSSRWater：明确许可的水面参考，当前不启用整套 SSR

[官方 Asset Library](https://godotengine.org/asset-library/asset/2152) · [源码](https://github.com/marcelb/GodotSSRWater) · [具体 shader](https://github.com/marcelb/GodotSSRWater/blob/main/shaders/water.gdshader) · [MIT 许可](https://github.com/marcelb/GodotSSRWater/blob/main/LICENSE.md)

- 官方社区目录列出 1.2 / Godot 4.4 / 2025-04-01；源码 README 标注 4.4.1，认为 shader 可运行于 4.3+。这表示有 4.x 更新，不等于 4.6.3、Android 和各 renderer 已验证
- 包含波浪、透明感、岸边效果和假折射；SSR 是自定义射线步进函数，并非调用 Godot 内置 SSR。因此“Mobile 不支持内置 SSR”不能推出“任何自定义 SSR 都无法实现”
- 当前 shader 读取屏幕／深度纹理，有逐像素循环，步数受最大距离和步长共同影响；还有多张波浪／法线纹理。源码的深度重建使用原始 depth 作为 NDC z，没有 Compatibility 分支，移植必须核验
- 作者明确说明 SSR 设置显著影响速度。Steam Deck 的作者自述不能推算 Snapdragon 手机帧率或温控表现
- 取舍：保留为将来 Mobile/Vulkan 画质实验参考；当前小水 shader 不抄入整套 SSR，避免将未测的 GPU 花销加入主路径

## 许可与集成纪律

三个候选均核查到 MIT 文本。若以后复制源码或实质片段，保留各自作者版权与完整许可，进入项目第三方声明和发行包可访问的许可信息；不要把“MIT”一句话当成保留通知。额外纹理、演示资产、子模块需要分别确认其许可，不能仅从根仓库许可推定所有内容均可复用。

当前报告没有复制任何候选源码；因此没有以本报告为由新增运行时第三方归属。Godot 自身现有许可记录继续适用。Blender 工具及导出作品的关系参考 [Blender 官方许可说明](https://www.blender.org/about/license/)。

任何候选正式采用前应锁定明确提交或版本，重新审查源码与许可证，并在已授权流程内完成安装／运行；本次只读研究不等于批准执行未知来源的 addon。

## 实施后应验证的内容（尚未执行）

1. 当前 renderer 下 shader 编译、深度／水边效果和反射；不能只跑 headless 后说画面正常
2. GLB 骨骼、权重、动作命名、抛竿时鱼线端点、手与鱼竿接触，反复切换动作无累计漂移
3. 清空／重建涟漪池和鱼线状态，覆盖重新进钓点、取消抛竿、断线、成功上鱼等路径
4. Android ARM64 导出和真实目标手机的帧时间、发热、持续负载、触控响应；桌面通过不代替真机
5. 若另做 Mobile renderer 版本，单独核验 Vulkan 运行和 GL 回退外观，勿静默把桌面 SSR 等级当作手机版最低要求
