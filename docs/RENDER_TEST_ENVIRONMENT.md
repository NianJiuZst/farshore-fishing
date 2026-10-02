# 桌面 Vulkan 图形回归环境

`tools/render_godot.py` 在一次进程生命周期中启动独立Xvfb和Godot，使用Mesa lavapipe进行真正的离屏桌面Vulkan绘制。它不是Godot的无渲染headless模式，也不是Android手机、GPU帧率或发热测试。截图必须标注桌面软件渲染。

工具全部来自Debian官方软件仓库，解包到被Git忽略的 `tools/xvfb`，没有替换系统驱动。版本与下载校验：

| 软件包 | 版本 | SHA256 |
|---|---|---|
| mesa-vulkan-drivers | 25.0.7-2+deb13u1 | caf2f7d296b7522efe74e40a74bce762a3ce84c33b53b5e54e1248ac2e0a13a5 |
| xserver-common | 21.1.16-1.3+deb13u3 | dc1d37303c103b23c40cd1ea694c5c6561e0e8dc1734a73c7a0ae0ef080e7fcc |
| xvfb | 21.1.16-1.3+deb13u3 | 365da2b6c93339f34337c434a9489bb6411a240fa47b9f49693d3091745f28c2 |

来源为 `https://deb.debian.org/debian/` 的trixie/main包索引及 `pool/main/m/mesa/`、`pool/main/x/xorg-server/`。下载后先与索引SHA256比对，再使用 `dpkg-deb -x` 解包，不调用未知安装脚本。发布源码不包含这些可重新取得的二进制软件包。

测试启动器隔离HOME/XDG数据目录，不接触真实玩家存档。当前执行沙箱不提供Unix显示套接字，因此测试X服务与Godot放在同一私有进程/网络环境中，通过127.0.0.1通信，保留X默认访问控制，不使用`-ac`。每次退出后终止自己的Xvfb。项目本身仍使用正式Android设备提供的Vulkan驱动。

显示服务只用本次进程私有临时目录中的一次性IPC认证文件，权限0600，退出随目录移除，不保存或输出其中的随机值。音频使用Dummy测试驱动以免无声卡环境产生误报；发行APK的音频驱动和设置不受影响。

2026-10-02，独立空工程实际启动日志确认：`Vulkan 1.4.305 - Forward Mobile - llvmpipe (LLVM 19.1.7, 256 bits)`。游戏截图另行逐场景审核，环境探针成功本身不代表游戏画面通过。

2026-10-02 19:04 UTC，执行环境重置后从上述Debian官方包目录重新取得相同三个版本，逐包SHA256与本表完全一致后解包，未改变固定版本或系统驱动。使用现有启动器在隔离HOME/XDG、一次性认证显示服务中运行320×180立方体场景，进程退出码0；日志确认 `PROBE_RENDERING_METHOD=mobile`、`PROBE_RENDERING_DRIVER=vulkan`、`PROBE_ADAPTER=llvmpipe (LLVM 19.1.7, 256 bits)`、`PROBE_CAPTURE=320x180 save_status=0`，并目视确认生成图像。临时显示服务已退出。忽略目录中的复验日志/图像为 `tools/xvfb/probe/probe.log` 与 `tools/xvfb/probe/probe.png`；图像SHA256为 `ec605a050db5935f8f6124f98350d5c54b81aa8f9519669e1c6d40af4ab86a43`。此结果仅证明桌面软件渲染工具恢复，不代表游戏场景或Android设备测试通过。
