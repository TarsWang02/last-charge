# Game Jam 工作流技术验证报告（Windows）

测试日期：2026-09-25 ｜ 机器：Windows 11 Pro，NVIDIA GeForce RTX 5070（驱动 610.88），显示器 165 Hz
Godot：**4.7.2.stable.official.ed1daf0bf**（标准版，非 .NET），路径 `D:\Godot_v4.7.2-stable_win64.exe`
所有“通过”项都由命令行实际运行得出（`main.gd` 内置 `--autotest` 自检，输出 JSON + 截图到 `shots/`）。

> 耗时说明：下面“耗时”是我（Claude）操作的实际时间，按对话中各步骤估算，精确到约几分钟；**不包含人工在编辑器里摸索的时间**。

---

## 1. 环境

**结果：通过 ｜ 耗时：约 5 分钟（导出模板 1.28 GB 下载占大头）**

- Godot 4.7.2-stable = GitHub 上当前最新稳定版（已通过 API 核对）。
- 导出模板：从官方 GitHub release 下载 `Godot_v4.7.2-stable_export_templates.tpz`，解压到 `%APPDATA%\Godot\export_templates\4.7.2.stable\`，含 windows_* 和 web_* 模板。
- Python 工具链：`tools/.venv`（miniconda 3.13 + soundfile 1.2.2 带 OGG 支持、numpy、pillow）。本机**没有 ffmpeg**，音频转换走 libsndfile。
- 卡点：`Downloads\Godot_v4.7.2-stable_win64.exe` 其实是解压出来的**文件夹**，不是 exe，直接调用会报 “not recognized”。已改用 D 盘版本。
- B 方案：队友机器上直接用官方 zip，编辑器内 *Editor → Manage Export Templates → Download* 装模板。**只有负责导出的那台机器需要装模板。**

## 2. 最小原型

**结果：通过（Forward+ / Compatibility / 导出的 exe 三处都跑过自检） ｜ 耗时：约 15 分钟**

自检实测（exe，Forward+）：

| 功能 | 自检结果 |
|---|---|
| WASD 移动（模拟按住 W 1 秒） | 走了 3.0 m ✅ |
| 鼠标视角（模拟 200px 位移） | 转了 0.5 rad ✅ |
| Esc 释放鼠标 → 设置面板出现 | ✅ / ✅ |
| 手电 F 关 / F 开 | ✅ / ✅ |
| 电量消耗（1.5%/s） | 2 秒掉 3.0% ✅，HUD 显示 `LIGHT xx%`，低于 20% 闪烁，耗尽自动关灯 |
| 会动的东西沿路径移动 | 1 秒走 1.2 m ✅ |
| 循环环境音 / 3D 定位音源 | 都在播放 ✅（**只证明在播放，声音好不好听要人耳去听，未测**） |
| 渲染缩放 0.5 生效 / 阴影 Low → atlas 1024 | ✅ / ✅ |

- 雾（普通雾 + 体积雾）、辉光（红色出口灯）、暗角、像素化、Bayer 抖动、颗粒、色差都在 `shaders/ps1_post.gdshader` 里。**参数全部能在编辑器调**：main.tscn → PostFX/Screen → Material → Shader Parameters。
- 接口：`Stalker`（scripts/stalker.gd）暴露 `model_scene`、`target_height`、`model_yaw_offset_deg`、`speed`、`anim_idle`、`anim_move`，代码里用 `set_moving(bool)` 切动作。放一个 `assets/models/creature.glb` 就会自动加载、缩放、脚贴地。道具同理：`prop.glb`。
- 卡点：①第一次截图画面几乎全黑，雾太浓把手电吃掉了。已调整：fog 0.08→0.025、体积雾 0.03→0.012、手电能量 4→8。②退出时报 `ERROR: 4 resources still in use at exit`，原因是自检在协程等待中途 quit，**正常游玩不受影响**。③鼠标“真的手感”只能靠注入事件测，**真人手感未测**。
- B 方案：如果 CSG 房间做大以后变卡，改用 MeshInstance + StaticBody，或者直接用 Tripo 出的整体场景。

## 3. 素材导入测试

### 3a. Tripo .glb（静态模型）
**结果：未测（inbox 里还没有真实文件） ｜ 管线本身：通过**
- 用合成的 `tools/testdata/prop_testcrate.glb`（带 256² 贴图）走完了检查 → 入库 → Godot 导入 → 游戏加载（日志 `[main] prop loaded`）全流程。
- 尺寸 / 朝向：游戏会自动缩放到 `prop_target_height`，并把底部对齐地面、水平居中。朝向歪了就改 `model_yaw_offset_deg`（生物）。
- 注意：Godot 导入 glb 时会把内嵌贴图**解出来**，生成 `xxx_0.png` 放在 glb 旁边，这是正常现象。

### 3b. Astra 带骨骼 .glb
**结果：未测（没有真实文件） ｜ 代码接口：通过**
- 合成的 `creature_test.glb`（节点动画 idle/walk，**没有蒙皮**）：日志 `[stalker] animations: ["idle","walk"]`，代码切换后 `anim_when_moving=walk`、`anim_when_idle=idle` ✅。
- **未验证**：真实骨骼蒙皮的变形、滑步。滑步要靠调 `Stalker.speed` 去对齐 walk 动画的步幅，只能肉眼看，必须拿真文件测。
- 风险：Astra 的片段名很可能是 “Take 001”、“mixamo.com”、“Armature|Walk” 这类。检查脚本会直接报 FAIL 并列出实际片段名；游戏这边在 Inspector 里改 `anim_idle` / `anim_move` 就能对上。

### 3c. Gemini 音频
**结果：未测（没有真实文件） ｜ 转换和检查：通过**
- 合成测试：`bgm_good.wav` PASS（接缝跳变 0.002）；`bgm_click.wav` 正确 FAIL（接缝跳变 0.63 + 响度 −3.9 dBFS 过大）。
- 入库时统一转 OGG Vorbis，响度归一到 −20 dBFS RMS，峰值限制在 0.98；3D 音源（`hum*`、`sfx3d*`）自动降为单声道。
- 注意：响度用的是 RMS，不是 LUFS，只能算粗略一致。

### 3d. 入库检查脚本 `tools/inbox.py`
**结果：通过 ｜ 耗时：约 10 分钟**
```
tools\.venv\Scripts\python.exe tools\inbox.py check            # 只检查
tools\.venv\Scripts\python.exe tools\inbox.py ingest --verify  # 检查+入库+Godot导入+启动游戏确认
```
检查项：格式 / glTF 2.0 合法性、面数预算（creature 6 万、prop 3 万）、世界空间尺寸（0.05–20 m 之外报警）、疑似躺倒（Z-up）、枢轴不在脚底、外链贴图（FAIL）、贴图 > 2048、有没有 idle 和 walk/run 片段、有没有蒙皮；音频采样率、削波、响度、BGM 接缝跳变、首尾静音。
命名规则：`creature_*.glb` / `prop_*.glb` / `bgm_*` / `amb_*` / `sfx_*`（详见脚本头注释）。
坏样本 `creature_bad.glb` 给出 2 个 FAIL + 5 个 WARN，原因都写清楚了。

## 4. 渲染对比（Forward+ vs Compatibility）

**结果：通过 ｜ 耗时：约 3 分钟** — 截图 `shots/forward_plus_*.png` 与 `shots/gl_compatibility_*.png`（同一机位）

| | Forward+ (Vulkan) | Compatibility (OpenGL 3.3) |
|---|---|---|
| 体积雾 | 有，手电有光柱雾感 | **不支持**（日志明确警告），只剩普通雾 |
| 整体亮度 | 较亮，光斑柔和 | 明显更暗、对比更硬 |
| 辉光 | 柔和扩散 | 更集中、更“烫” |
| 阴影 | 干净 | 箱子阴影边缘出现**紫色竖条伪影** |
| 后处理 shader | 一致 | 一致（像素化 / 颗粒 / 色差 / 暗角都生效） |
| 帧率（RTX 5070，关 vsync，720p） | 1650–2290 | 1520–1830 |

结论：同一套灯光参数在两个渲染器下观感差别很大。**比赛只调一个渲染器**，另一个别指望“差不多”。

## 5. 导出

**结果：部分通过 ｜ 耗时：约 5 分钟**

- **Windows exe：通过**。命令行导出约 3 秒，单文件 `build/win/JamTest.exe`（109 MB，pck 已嵌入）。实际启动跑了自检，全部项目通过，退出码 0。
- 本机帧率（exe，Forward+）：关 vsync 时 2287（0.5 缩放 + 低阴影）/ 1710（1.0 + 中）/ 1656（1.0 + 高）；开 vsync 锁 165。
- **集显电脑：未测**（没有第二台机器）。可以在那台机器上跑：`JamTest.exe -- --autotest --shots=C:/temp --novsync`，然后看 `%APPDATA%\Godot\app_userdata\Jam Test\logs\godot.log` 里 AUTOTEST 那行的 avg_fps。
- **网页版：部分通过**。导出约 3 秒（wasm 39 MB，单线程版，不需要 COOP/COEP 头）。本地起 http 服务后，在内置浏览器中能加载，自动退回 Compatibility（`rendering_method.web`），画面和后处理都正常。
  - 失败 / 未测：①**帧率未测**，内置浏览器面板处于隐藏状态，requestAnimationFrame 被节流到约 1.7 fps（连静态页面也一样），这个数字不代表游戏性能。②Pointer Lock 在内嵌面板里报 `WrongDocumentError`，真实浏览器里要点击画面后才能锁鼠标，**未测**。③Web 版没有体积雾。
- B 方案：网页版只当“能玩的预览”。主推 exe 打 zip 传 itch.io；itch 上可同时挂 web 版（选 nothreads，免配置 SharedArrayBuffer）。

## 6. 计时：新 glb 放进 inbox → 出现在游戏里

**结果：通过（用合成文件测得）**

| 步骤 | 时间 |
|---|---|
| 检查 5 个文件 | < 0.1 s |
| 复制 + 音频转码 | < 1 s |
| Godot 无头导入 | 2.7 s |
| 启动游戏自检确认已加载 | 18.4 s |
| **合计（脚本）** | **21 s** |

加上人工操作（下载、改名、看一眼效果），估计 **1–2 分钟/个**。真实 Tripo 模型面数多、贴图大（2k–4k），导入会慢一些，**未测**。如果要换 Astra 的动画片段名，再加 1 分钟改 Inspector。

---

## 7. 第一批真实素材（2026-09-25）

### GPT Image 概念图：通过（人工评估）
所有要求的元素都有，适合定氛围和配色；精细度远高于 PS1，不能当成画面目标。它带出两个新需求：湿地面反射（已开启 SSR，只有 Forward+ 支持），以及墙面“下半截瓷砖、上半截灰泥”的双材质（**还没做**）。

### GPT Image 瓷砖贴图：通过
- 检查：1254²，接缝指标 LR 1.12 / TB 1.24（≈1 表示无缝，> 2.5 判失败），四个象限亮度差 2.9，没有自带明显光照；唯一 WARN 是“不是 2 的幂次”。
- 入库时缩到 512²，整个流程 < 1 秒。游戏自动贴到墙上（`shots/forward_plus_wall_closeup.png`）。
- 调参时踩的坑：①色差把细缝线拆成红绿双线 → chroma 0.012 改为 0.006；②最近邻采样让缝线粗细不均 → 改线性过滤 + mipmap；③瓷砖尺寸 15 cm → 20 cm；④贴图太亮 → 材质乘暗黄色；⑤手电近距离过曝 → 能量 8 改 6，衰减 0.8 改 0.5。**这 5 项调整加截图验证共用了约 10 分钟，比赛时要预留。**

### Gemini 环境音 `Drip_in_Ward_Four.mp3`：失败 → 自动修复后通过
- 原文件：MP3 128k，44.1k 立体声，61.4 s，−14.4 dBFS RMS（全程稳定），峰值 −0.2（接近削波）。**结尾约 3 s 淡出 + 1.9 s 静音，无法直接循环。** 提示词写了 “no fade out”，Gemini 没照做。
- 入库新增自动循环处理：切掉首尾静音 → 检测淡出起点并切掉 → 2 s 等功率交叉淡化，把结尾接到开头。结果：55.2 s，接缝处的采样跳变 0.0018（正常相邻采样约 0.0014），响度归一到 −19.8 dBFS，重新检查 PASS。**听感：未测（需要人耳确认）。**
- 新发现的 bug（已修复）：libsndfile 一次写入长 OGG 会栈溢出（Windows 错误码 0xC00000FD），改为每次写 1 秒。

### 耗时
两个文件从 inbox 到出现在游戏里：23 s（脚本），另加约 10 分钟调画面参数。

## 8. Tripo 机器人模型（2026-10-02，`robot 3d model.glb`）

| | 原始文件 | `slim_glb.py` 处理后 |
|---|---|---|
| 三角面 | **1,893,186**（入库检查 FAIL，预算 2–3 万） | 28,558 ✅ |
| 贴图 | 8192² 基础色 + 4096² 法线 + 4096² 粗糙度 | 2048² + 1024² + 1024² |
| 文件 | 66.5 MB | 2.0 MB |
| Godot 导入 | 34.7 s | 约 4 s |
| 场景加载 | 2150 ms | 147 ms |
| 显存（整个场景） | **1285 MB** | 202 MB |
| 帧率（RTX 5070，关 vsync） | 约 1470 | 约 1520 |
| 观感（第三人称约 3 m） | — | 截图几乎看不出差别 |

- 处理工具：`tools/slim_glb.py` = gltfpack 减面（保留 UV）+ PIL 缩小贴图，**不需要 Blender，3.6 秒**。需要 Node.js 和 gltfpack（`npm i -g gltfpack`）。
- 结构：**只有一个网格**，头、手臂、履带没有分开 → 策划书里的刚性部件动画（转头、手臂、履带）**做不了**，必须在 Blender 里拆件。
- 动态：整体运动（行驶绕圈、转弯侧倾、履带抖动、待机呼吸、跳跃的挤压和拉伸）用代码驱动都能跑；单网格模型能做的也就只有这些。
- 造型：和策划书高度一致（方头、铆钉、青色圆眼、钳子手、履带、背后 5 格电芯、发条钥匙）。但**眼睛和电芯是画在贴图上的**，不能单独发光、逐格熄灭 → 需要在 Godot 里叠加发光部件。配色比“褪色芥末黄”更鲜艳、偏柠檬绿。
- 后处理：diorama 预设（不像素化、轻颗粒、轻暗角、景深）和策划书匹配；PS1 预设会把细节压糊，不适合这个项目。截图在 `shots/robot_*.png`。

### 8b. Codex + Blender 拆件（`robot_parts.glb`）：通过
- Codex 用 Blender 5.2.2 无界面脚本拆出 Body / Head / Arm_L / Arm_R / Track_L / Track_R / WindKey，30,970 三角面，贴图逐字节未变。耗时约 18.5 分钟（含安装 Blender），脚本复跑 2.9 秒。我这边复核：入库 PASS，Godot 导入 4.4 秒，场景加载 152 ms，显存 202 MB。
- `scripts/robot_rig.gd`（`RobotRig`）驱动部件：转头 30°、歪头 15°、双臂抬 45°、钥匙旋转、行驶时双臂摆动和履带抖动，**枢轴全部正确**（`shots/robot_diorama_parts_pose_test.png`）。
- 程序化发光：两只眼睛 + 5 格电芯叠加在模型上，随电量变化：青 → 琥珀（≤60%）→ 红（≤20%），最后一格闪烁；低电量时眼睛半眯、手臂下垂（`shots/robot_diorama_parts_charge_*.png`、`eyes_low.png`）。
- 局限：履带是刚性的，**履带面不能滚动**（所有部件共用一张贴图，没法单独滚动 UV），只能用上下抖动示意；另一侧的钥匙状装饰留在 Body 上，不会转。
- 坑：新建带 `class_name` 的脚本后，必须先跑一次 `--import`（或者打开编辑器）才能被识别；否则场景加载失败，自检会卡住不退出。

---

## 比赛当天最大的 3 个风险

1. **Astra 骨骼动画是最大的未知数**：变形、滑步、片段名、根运动都没用真文件验证过。→ **比赛前请把一个真实的 Astra 导出放进 inbox 跑一遍**。B 方案：怪物不用骨骼动画，只用节点动画（浮动 / 抖动 / 瞬移），在恐怖游戏里反而更吓人。
2. **光照调参吞时间，而且两个渲染器表现不一致**：第一次跑就是全黑。队友的电脑、比赛的投影 / 屏幕亮度也不一样。→ 定死 Forward+ 只调这一个；后处理参数先定好“默认值”，别人别碰；设置面板加一个亮度 / gamma 滑条（当前没有）。
3. **集显性能未知**：Forward+ + 体积雾 + 动态阴影在集显上可能很卡。→ 赛前找一台集显笔记本跑一次自检；B 方案用低画质预设（缩放 0.5 + 阴影 Low），或者关掉体积雾。

另外：Tripo 模型面数 / 贴图过大（脚本会拦）；3 人协作时 .tscn 合并冲突（建议一人管场景，其余人只往 inbox 投素材）。

## 版本与渲染器建议

- **Godot 4.7.2-stable**（标准版），导出模板 4.7.2.stable，全队统一。
- **渲染器：Forward+**。体积雾和光柱是这类恐怖氛围的核心卖点，本机帧率余量很大。网页版会自动退回 Compatibility，只当附带预览。只有在集显实测不行时，才考虑整体切到 Compatibility，而且要重新调光。
