# 卧室剩余模型与当前进度

更新：2026-10-03。范围包括卧室背景、床头柜、纸箱与书桌。

## 仍待 Tripo 返回：4 组

| 项目 | 当前游戏状态 | 参考图 |
| --- | --- | --- |
| 厚被子＋枕头 | 仍为白模，等待组合 GLB | bedroom_finish/tripo_references/01_bedding |
| 侧睡老人上半身 | 仍为人物白模；参考已改为抽象、模糊的澳洲家庭老人 | bedroom_finish/tripo_references/02_sleeping_grandfather |
| 写作业少年 | 仍为人物白模；参考已改为浅棕发、模糊五官的澳洲少年 | bedroom_finish/tripo_references/03_seated_teenager |
| 瓷娃娃头 | 两个球体；只生成一个模型，复用为 8 cm 和 6 cm 两个版本 | bedroom_finish/tripo_references/04_porcelain_doll_head |

参考图完整路径在 docs/art_production_20261003/bedroom_finish/tripo_references/ 下。每项有四张独立图片及 prompts.json；该目录的 README.md 说明 Tripo 参数、尺寸和交付方式。

## 本批自制并接入：6 类，7 个 GLB

| 项目 | 接入结果 |
| --- | --- |
| 床垫 | 固有色布料、包边、侧面条纹与提手；顶面高 0.55 m |
| 小玩具卡车 | 旧漆车身、驾驶室和车轮；车斗顶面 0.14 m，驾驶室顶面 0.19 m |
| 黄铜壁灯 | 空心灯罩、灯臂、灯泡；随原节点在书桌俯视模式中隐藏并恢复 |
| 南侧窗户 | 木框、横档、玻璃与窗台，沿用北窗配色 |
| 卧室门和把手 | 分为门扇、活动把手两个模型，继承原 DoorPivot 和 Handle 动作 |
| 大机器人头顶 U 形车轨 | 三段轨道的位置与厚度保留，小车路线不变 |

这些模型已进入 inbox/ 和 assets/models/props/，通过 scripts/bedroom_finish_art.gd 接入。原碰撞保留，尺寸与动作检查、既有关卡回归和种子 7 的实际试玩通过。

## 之前已替换，不重复生成

- 床头柜及其全部物品：书、药瓶、水杯、眼镜、硬币、相框等。
- 床架、床头板、书桌结构、椅子和书桌迷宫道具。
- 北窗及地板、墙面材质。
- 大机器人、兔子、熊、小丑、猴子。
- 纸箱、鞋盒、积木、环形火车轨道和车厢、玩偶匣及机关部件。
- 字母积木、电池、玩具鼓、尺子、支点与出口小车。

毛绒玩具下的落地垫已有简易外观，可后续精修，不占 Tripo 次数。所有可站立面继续以白模为准，允许误差 ±1 cm。
