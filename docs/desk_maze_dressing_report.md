# 书桌迷宫美术验收报告

日期：2026-10-03。正式随机池：**0、7、22、49**。

## 交付

- 新增 32 个实际 GLB；全部自制，Tripo 消耗 **0 次**。inbox/ 与 assets/models/props/ 各有一份。没有占位块；缺失资源回退功能保留。
- 源模型、制作脚本、512px 固有色贴图和资产尺寸/面数表见 docs/desk_maze_delivery/。不烘焙光照或 AO，普通道具使用褪色红蓝、米白、芥末黄与墨绿。
- A1/A2/A3 共 8 件，叠放件 2 件，立柱/高柱 5 件，纸张 4 件，断木 2 件，散落物 4 件，关键物 7 件。生日卡和奖状每局合计 1–2 件。
- 保留全部原碰撞、关键物坐标及公开 API。独立装饰随机源为 used_seed * 7919 + 1；装饰代码不读取 path。墙面投影宽度控制到 3.6 cm；长件的偏航相应缩小，沿墙抖动限制在 1 mm，以保护窄通道和闭合段端点。
- 纸张完全放在有效地板格内，不跨缺口。断木伸入洞口小于 1 cm，黑底面低于桌面 5 cm。散落物为 4 个 MultiMesh，无投影；紙张无投影。
- 9.5 cm 橡皮外形、随动父节点及折叠便条材质发光已验证。灯头使用 target_offset 定向；原光照和检查点逻辑保留。
- tools/gen_room.py 默认生成及 --desk-seed-pool-only 均保存所选池；后者只修改已有 DeskMaze 节点，避免覆盖同时制作的电视关卡。

## 验收

| 种子 | 主路线格数 | 缺口 | 第 0/1/2 站布尔项 | 路线额外重生 | 截图目录 |
|---|---:|---:|---|---:|---|
| 0 | 25 | 13 | 全部通过 | 0 | shots/dress_0/ |
| 7 | 29 | 10 | 全部通过 | 0 | shots/dress_7/ |
| 22 | 27 | 15 | 全部通过 | 0 | shots/dress_22/ |
| 49 | 27 | 11 | 全部通过 | 0 | shots/dress_49/ |
| 123 | 23 | 18 | 全部通过 | 0 | shots/dress_123/ |
| 4242 | 19 | 9 | 全部通过 | 0 | shots/dress_4242/ |

每个目录都有 room_s2_dark.png、room_s2_flashlight.png、room_s2_goal.png。全局光总览：shots/maze_seeds/seed_7.png、seed_22.png、seed_49.png；已目视检查通道、黑色缺口和关键物，以及不按主路线改变杂物密度。暗场维持原来的局部照明，未擅自提高环境亮度。

对全部六个种子的 dressed=false/true 比较：path、holes、open、RNG 状态、全部 CollisionShape 的尺寸与变换、灯具规格和便条格完全一致。墙件/立柱/叠放合计未超过 250；纸张未超过 60；便条材质发光检查通过。详见 final_layout.log。

游戏自测使用真实图形窗口运行，1280×720、60 FPS。正式项目因并行制作电视关卡，增加 --desk-autotest 在第 2 站结束后打印报告并退出；普通 --autotest 的后续电视测试仍保留。独立副本另跑了原命令的完整第 0/1/2 站验收。

```powershell
D:\Godot_v4.7.2-stable_win64_console.exe --path . res://scenes/room.tscn -- --autotest --desk-autotest --shots=shots/dress_7 --maze-seed=7
D:\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/test_desk_dressing.gd
D:\Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/maze_seeds.gd -- --render
```

## 性能与导出

RTX 5070，1280×720，同一书桌俯视位置、同一手电照明，5 次 TIME_FPS 采样，--max-fps=0；同一最终项目版本中的顺序对照为 **173.8 → 173.2 FPS**，测得下降约 **0.35%**（5 次采样分别为 174/173/173/174/175 与 174/173/174/172/173）。显示同步仍约束在 180 FPS，因此这是开发机正常显示条件的测量，不能据此推断无限制渲染吞吐。实际游戏验收限帧 60 FPS，各种子记录均为 60。早期一轮为 180 → 177.4 FPS（下降 1.4%）。详情见 perf_before.log、perf_after.log。

Windows Desktop 导出结果见 export_result.json；exit code=0，且 JamTest.exe 修改时间严格晚于导出开始。build/win/JamTest.exe 为新版本。旧版 exe 占用导致第一次导出失败，已关闭旧预览并重新成功导出；没有将旧 exe 当作新版本。打包版主菜单启动检查通过。

## 限制与未测

- 小薄片的通用入库检查会给出“高度小于 5 cm”提示；这里是按设计制作的米制小道具，全部 32 件没有 FAIL。回形针 96 面，纸团 320 面；一些简单尺子、纸张和小零件低于一般小道具 500 面建议，保留以节省性能。
- 打包版完整通关：未测；路线验收是在 Godot 图形运行模式下完成。电视新增流程不属于本次书桌验收，未测试；已保留其并行改动。
- 非必做的随身听、零食包装、耳机线、同学录等扩展模型未制作；当前已覆盖全部必做组与两类情感纸张。
