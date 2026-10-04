# 游戏文本（Last Charge）

> 游戏内显示英文。**要改措辞只改 `scripts/story_text.gd`**，显示逻辑在 `scripts/captions.gd`，不依赖具体字符串。
> 中文是给队友审稿用的对照，不进游戏。
> 叙事约定：**全程第一人称**。老人睡着后，灵魂进了他小时候那只铁皮机器人（全家福里他抱着的那只）。完整独白见 `docs/narrative_monologue_script.md`，这里的句子与它保持一致。

## 怎么显示

| 类型 | 时机 | 位置 / 样式 |
|---|---|---|
| 开场一句 | 点 Start、淡入卧室后自动播放（`--autotest` 时跳过） | 画面上方 1/3，白字，淡入淡出 |
| 操作提示 | 开场那句之后，显示 8 秒 | 底部小字，半透明 |
| 记忆卡片 | `Game.restore_memory(id)` 触发时 | 底部居中：琥珀色小标题 + 白色正文；多个会排队 |
| 配电箱 / 结局 | **故意不加字**：结局是一镜到底的无字镜头 | — |

接口（以后要加字时用）：
```gdscript
Game.captions.play_lines([["text", 3.0]])   # 居中逐句播放，可 await
Game.captions.show_line("text", 2.0)         # 单句
```

## 开场

| English | 中文 |
|---|---|
| ...Where am I? | ……这是哪儿？ |

操作提示：`WASD move · SPACE jump · MOUSE look · E use (costs charge)`

## 记忆

| id（触发位置） | 标题 | 正文 | 中文 |
|---|---|---|---|
| `family_photo`（第 0 站，扶起相框） | The family photo | Christmas, '53. Mum, Dad... and me, / hanging on to that robot like it was gold. | 53 年圣诞。妈，爸……还有我，／抱着那个机器人，跟抱着宝贝似的。 |
| `mom_note`（第 2 站，书桌迷宫里的纸条） | Mum's note | "Back soon." She always was. / Till the one time she wasn't. | "马上回来。"她每次都说到做到。／只有那一次没有。 |
| `time_box`（第 3 站，电视旁的时光盒） | My time box | My drawing. Me and the robot, beating the dragon. / Thought I'd be a hero. Ended up a farmer. Not a bad trade. | 我的画。我和机器人，一起打败恶龙。／那时候以为自己会当英雄，后来当了农民。也不亏。 |
| `daughter_mug`（第 4 站，窗边女儿的杯子） | Lucy's mug | She painted it when she was five. / Still rings the same. She doesn't ring as often. | 她五岁时画的。／敲起来声音还跟从前一样。只是她现在不常打电话来了。 |

## 需要队里确认的设定

1. **年份 '53**：按八十来岁的老人算（1946 年生）。全家福贴图是 70 年代风格的服装，对不上的话可以改贴图，或者去掉年份。
2. **女儿名字 Lucy**：随便起的，可以改。
3. **结局不加字**：保留 room.gd 里一镜到底的无字结局。
4. **没有逐站标题**（比如 "Childhood"）。现在的设计几乎不用文字，我觉得不加更好。

---

## itch.io 页面

**Short description（一句话简介）**
> A 10 cm tin robot crosses a dark farmhouse on its last charge.

**正文**
> The power went out at 2:14 a.m.
>
> A little tin robot wakes on an old man's nightstand. To get the lights back on, it has to cross the whole house — the toy box, the messy desk, the TV, the flooded kitchen — on a battery that won't last.
>
> Everything you power costs charge. Every room is a little piece of someone's life.
>
> **Controls**
> - WASD — move
> - Space — jump
> - Mouse — look
> - E — use / power things (costs charge)
> - Right mouse — electromagnet (grab steel overhead)
> - Esc — pause & settings
>
> Best with headphones, lights off.
>
> Made in 48 hours for the ANU CSSA Game Jam 2026 — theme: *Losing Power*.

**Credits**（待填）
> - Team: …
> - Engine: Godot 4.7.2
> - 3D models: Tripo (AI-assisted) + hand-made in Blender
> - Audio: …
