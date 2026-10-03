# Last Charge

ANU CSSA Game Jam 2026（主题：Losing Power）。一只 10 cm 的铁皮机器人，在停电的农舍里绕全屋走一圈，回到配电箱。

## 开始

1. 安装 **Godot 4.7.2**（Forward+）和 **Git LFS**。
2. 克隆仓库后运行一次：
   ```
   git lfs install
   git lfs pull
   ```
3. 用 Godot 打开 `project.godot`。第一次打开会导入素材，需要几分钟。

## 目录

| 位置 | 内容 |
|---|---|
| `scenes/` | `title.tscn`（标题）→ `room.tscn`（整栋房子）。**`room.tscn` 是生成的，不要手改**，见下面"白模"。 |
| `scripts/room.gd` | 各站的关卡逻辑和自测 |
| `scripts/tps_player.gd` | 机器人控制器：移动、跳跃、推箱子、俯视、电磁吸附、蒸汽 |
| `scripts/tv_game.gd` | 电视里的像素游戏 |
| `scripts/desk_maze*.gd` | 书桌随机迷宫和桌面杂物装饰 |
| `scripts/components/` | 存档点、可互动物、可推箱子、水和火的伤害区域等 |
| `tools/gen_room.py` | **白模生成器**：所有尺寸都在这里（真实米 × 9）。改完运行它，重新生成 `room.tscn` |
| `tools/check_layout.py` | 检查白模里的物体有没有重叠 |
| `tools/inbox.py` | 素材入库检查 |
| `assets/` | 模型、贴图、音频（走 LFS） |
| `docs/` | 美术、音频需求和交付报告 |

## 白模

```
tools/.venv/Scripts/python.exe tools/gen_room.py
```
运行后会重写 `scenes/room.tscn`。所以要改场景布局，就改 `gen_room.py`。美术模型是由 `scripts/room_art.gd` 套在白模碰撞体上的。

## 测试

自测会用模拟按键把关卡实际玩一遍，并保存截图：
```
godot --path . res://scenes/room.tscn -- --autotest --shots=shots/run1           # 从头到尾
godot --path . res://scenes/room.tscn -- --autotest --from=tv --shots=shots/tv     # 只测电视
godot --path . res://scenes/room.tscn -- --autotest --from=kitchen --shots=shots/k # 只测厨房
```
输出里 `ROOMTEST` 那一行的每一项都应该是 `true`。

**调试快捷键**（游戏里）：F9 跳到卧室门口，F10 跳到厨房。

## 协作约定

- **改文件前先拉取最新版本（`git pull`），只改自己负责的部分，不要整个文件覆盖。**
- 改场景布局只改 `tools/gen_room.py`，不要手改 `room.tscn`。
- 提交前至少跑一次相关关卡的自测。
- 大文件（模型、贴图、音频）会自动走 LFS，不要关掉 LFS 再提交。
- 导出的程序（`build/`）、截图（`shots/`）和原始素材（`inbox/`）不进仓库。
