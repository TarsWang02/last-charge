# 游戏文本（Last Charge）

> 游戏内显示英文。**要改措辞只改 `scripts/story_text.gd`**，显示逻辑在 `scripts/captions.gd`，不依赖具体字符串。
> 中文是给队友审稿用的对照，不进游戏。
> 叙事约定：机器人就是全家福里男孩抱着的那只玩具，所以文本里用 **"you"** 称呼机器人；老人是那个男孩，各站是他的人生阶段（童年 → 少年 → 青年 → 为人父 → 晚年）。

## 怎么显示

| 类型 | 时机 | 位置 / 样式 |
|---|---|---|
| 开场两句 | 点 Start、淡入卧室后自动播放（`--autotest` 时跳过） | 画面上方 1/3，白字，淡入淡出 |
| 操作提示 | 开场两句之后，显示 8 秒 | 底部小字，半透明 |
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
| The power went out at 2:14 a.m. | 凌晨 2:14，停电了。 |
| Everyone in the house was asleep. / Almost everyone. | 屋里的人都睡着了。／几乎所有人。 |

操作提示：`WASD move · SPACE jump · MOUSE look · E use (costs charge)`

## 记忆

| id（触发位置） | 标题 | 正文 | 中文 |
|---|---|---|---|
| `family_photo`（第 0 站，扶起相框） | The family photo | Christmas, 1979. / He wouldn't put you down all day. | 1979 年圣诞。／那一整天，他都没把你放下。 |
| `mom_note`（第 2 站，书桌迷宫里的纸条） | Mum's note | "Back soon. Finish your maths." / He never did finish the maths. | "马上回来。把数学写完。"／那道数学题，他始终没写完。 |
| `time_box`（第 3 站，电视旁的时光盒） | The time box | A crayon knight, a dragon, and a little yellow robot. / Underneath, in big letters: MY BEST FRIEND. | 蜡笔画的骑士、恶龙，还有一个黄色的小机器人。／下面用大大的字写着：我最好的朋友。 |
| `daughter_mug`（第 4 站，窗边女儿的杯子） | Lucy's mug | She painted it when she was five. / It still rings the same. | 这是她五岁时画的。／敲起来，声音还和从前一样。 |

## 需要队里确认的设定

1. **年份 1979**：全家福的服装风格是 70 年代末。男孩当年约 7 岁，到现在（2026 年）大约 54 岁，不太算"老人"。如果老人要显老，可以改成 **1958**（现在约 75 岁），但 70 年代的照片风格就对不上了。二选一，或者干脆不写年份，只写 "Christmas morning."
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
