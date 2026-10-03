# 机器人刚性拆件报告

Blender：5.2.2 LTS；命令行无界面运行。

坐标均为 glTF / Godot 世界坐标（米，Y 朝上）；前方为 +Z，机器人自身左侧为 +X。所有节点缩放为 1，Robot 位于 (0,0,0)。

| 部件 | 三角面 | 包围盒最小值 | 包围盒最大值 | 世界枢轴 |
|---|---:|---|---|---|
| Body | 11675 | (-0.341614, 0.048712, -0.245000) | (0.207000, 0.610000, 0.253197) | (0.000000, 0.049000, -0.000000) |
| Head | 6848 | (-0.237061, 0.610000, -0.133560) | (0.236450, 0.980011, 0.236496) | (0.000000, 0.610000, -0.000000) |
| Arm_R | 1729 | (-0.442780, 0.210510, -0.017902) | (-0.207000, 0.572938, 0.266068) | (-0.207000, 0.535000, -0.000000) |
| Arm_L | 1745 | (0.207000, 0.211670, -0.017532) | (0.443848, 0.572525, 0.267197) | (0.207000, 0.535000, -0.000000) |
| Track_R | 4576 | (-0.332489, 0.000427, -0.266525) | (-0.145000, 0.280000, 0.332199) | (-0.235000, 0.125000, -0.000000) |
| Track_L | 4002 | (0.145000, 0.000366, -0.292130) | (0.332092, 0.280000, 0.307877) | (0.235000, 0.125000, -0.000000) |
| WindKey | 395 | (0.162765, 0.392792, -0.331924) | (0.193542, 0.580086, -0.245000) | (0.178000, 0.478000, -0.205000) |

## 方法与质量

先实际 Separate by Loose Parts，得到 628 个 UV 接缝碎片；重合位置连通检查为一整体。保持 loop UV，合并 1 微米内重合位置，再用 bmesh bisect 在脖子、肩部和履带轴连接处切割，钳子下半段按连通岛重新归并。没有减面、重拓扑、烘焙、骨骼或动画。

头部、眼睛和头顶零件完整属于 Head；双臂包括活塞与完整钳子；履带包括轮子和内侧轴套。电池舱保持在 Body。Body 底部枢轴位于中央下部支架的底端（不是机器人脚底）。

原 AI 模型两侧都有钥匙状结构：+X 后侧薄钥匙分出 WindKey；-X 肩后另一个厚的钥匙状装饰与背部框架归入 Body，避免随肩膀转动或强行分成两个不同轴的钥匙。WindKey 的连接轴为 Godot Z（Blender Y），Godot 可绕本地 Z 旋转；枢轴放在杆插入背部框架处。

局限：这是刚性切面，不是新建机械关节；极大角度时可看到原模型融合部位与新增端盖。原 AI 模型的凹陷、非对称和表面细节保留。动作测试为头转 30°/歪 15°、双臂抬 45°、钥匙转 90°；附背面动作图方便查看钥匙。

## 补洞

每个 bisect 新生成的开口使用 holes_fill 封盖，同一个材质；补面 UV 使用默认值。脖子、肩侧、轴套和钥匙杆端盖位于关节内侧；腕部 z=0.280 分区两半最终同属手臂，内部端盖不会随动作张开。切割位置（以下为 Blender 坐标）：
- neck z=0.610 / negative：1 个多边形端盖。
- neck z=0.610 / positive：1 个多边形端盖。
- lower partition z=0.280 / negative：9 个多边形端盖。
- lower partition z=0.280 / positive：9 个多边形端盖。
- key stem y=0.245 / negative：1 个多边形端盖。
- key stem y=0.245 / positive：1 个多边形端盖。
- left shoulder x=-0.207 / negative：2 个多边形端盖。
- left shoulder x=-0.207 / positive：2 个多边形端盖。
- right shoulder x=0.207 / negative：1 个多边形端盖。
- right shoulder x=0.207 / positive：1 个多边形端盖。
- left track axle x=-0.145 / negative：3 个多边形端盖。
- left track axle x=-0.145 / positive：3 个多边形端盖。
- right track axle x=0.145 / negative：3 个多边形端盖。
- right track axle x=0.145 / positive：3 个多边形端盖。

## 实际验证

原始 28542 三角面；导出重新导入 30970 三角面，变化 8.51%；包围盒最大端点误差 0.000000000 m。
- names：PASS
- hierarchy：PASS
- triangle_count：PASS
- bbox：PASS
- materials：PASS
- embedded_textures：PASS
- no_animation_skin：PASS
- texture_bytes_unchanged：PASS

三张嵌入贴图的 SHA-256 与输入逐字节一致；尺寸、编码及像素均未改变。原始表面 UV 保留，切割新增顶点 UV 由原三角面插值。导出 1 个材质，7 个网格，未导出相机、灯、动画和蒙皮。

## 耗时

从任务初始检查到本轮导出完成：1111.3 秒（包含下载安装、权限等待、预览和修正）。
最终脚本：导出完成 0.764 秒；包括渲染与重新导入检查共 2.931 秒。早期预览和试切轮次未保存独立运行日志，也未汇总计时；脚本运行时间为进程内测量，不包含 Blender 启动。
真人熟练操作估计 1–2 小时，含辨认 AI 融合边界、拆件、端盖、原点、导出和验证；这是估计，不是实测。

## 复现

```powershell
& 'D:\AI\Blender\blender.exe' -b -P 'C:\Users\Thunder\jam-test\tools\blender\split_robot.py' -- --input 'C:\Users\Thunder\jam-test\assets\models\robot_lo.glb' --output 'C:\Users\Thunder\jam-test\inbox\robot_parts.glb'
```

项目入库检查：实际运行，退出码 0，耗时 0.192 秒；无 FAIL。

Godot 4.7.2 无头导入：隔离项目实际运行，退出码 0，耗时 4.348 秒；无 ERROR。

为遵守不修改 assets/scenes/scripts，未运行原项目路径的 --import（会生成 assets 下的 .import 文件）；使用 tools/blender/godot_validation 最小项目导入同一 robot_parts.glb。完整游戏项目导入：未测。

入库命令：`C:\Users\Thunder\jam-test\tools\.venv\Scripts\python.exe C:\Users\Thunder\jam-test\tools\inbox.py check`

Godot 命令：`D:\Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Users\Thunder\jam-test\tools\blender\godot_validation --import`

导出器有 sampler 选择警告（原材质同一贴图有多个节点）；嵌入三张图片逐字节验证相同。Blender 受限运行中用户配置缓存写入被拒绝，不影响模型输出和检查。
