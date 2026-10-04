# Last Charge：独白脚本（草稿 v2）

> **设定**：老人睡着了，灵魂进了他小时候那只铁皮机器人里。全程是**他的第一人称内心独白**：一开始不知道自己在哪、是谁，一路认出自己的家、自己的一辈子，最后把剩下的一点电交出去，让屋子亮起来。本文件目前只有**序章和第 1 站**。
> **口吻**：澳洲乡下老头，八十来岁。话少、朴实，带点自嘲，不煽情。澳洲用词点到为止（Mum、reckon、struth、righto、old girl），不要满屏 "mate"。
> **人设**（可改）：1946 年生；妻子 **Marg**（Margaret，已去世）；女儿 **Lucy**；全家福是 **1953 年圣诞**，他 7 岁，手里抱的就是这只机器人（50 年代正好是铁皮机器人流行的年代）。
> **格式**：游戏里用英文，中文是给队友对照的。每句尽量控制在一行以内。"触发"一栏写的是 `room.gd` 里已有的函数或区域，方便之后接线；标 ★ 的是**目前没有对应镜头或事件、需要新加**的。

---

## 序章 · 床头柜（现在）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 0-1 | 开场，淡入后 | ...Where am I? | ……这是哪儿？ |
| 0-2 | ★ 镜头扫到床上睡着的老人 | Hang on. That's my bed. | 等等，那是我的床。 |
| 0-3 | ★ 同上，停在老人脸上 | And that's... me. | 床上那个……是我。 |
| 0-4 | ★ 低头看自己的铁皮手 | Then who's this? | 那现在这个……是谁？ |
| 0-5 | `_reveal_desk`（镜头转向台灯，书桌前坐着少年） | Who's that at my desk? ...At this hour? | 谁坐在我的书桌那儿？……这么晚了？ |
| 0-6 | `_stand_frame_up`（按 E 扶起全家福） | Christmas, '53. Mum, Dad... and me, hanging on to that robot like it was gold. | 53 年圣诞。妈，爸……还有我，抱着那个机器人，跟抱着宝贝似的。 |
| 0-7 | 紧接 0-6 | ...That robot. That's *this*. I'm in my old tin robot. | ……那个机器人，就是现在这个。我在我那只旧铁皮机器人里头。 |
| 0-8 | `_fall`（书翻倒，滑进纸箱） | Whoa— struth! | 哎——要命！ |

## 第 1 站 · 玩具箱（童年）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 1-1 | `_fall` 落地后 | My old toy box. Mum swore she'd chucked this out. | 我的旧玩具箱。妈当年发誓说早扔了。 |
| 1-2 | 碰到箱底的黑暗、被送回检查点（第一次） | Don't like the dark down there. Never did. | 底下那片黑，我不喜欢。从小就不喜欢。 |
| 1-2b | ★ 第一次站上小火车（`components/toy_train.gd`） | All aboard. Dad built that track. | 上车喽。那条轨道是爸爸搭的。 |
| 1-3 | `_jack`（小丑盒弹出） | Still scares the daylights out of me. Seventy years on. | 七十年了，还是能把我吓个半死。 |
| 1-4 | ★ 第一次看到大铁皮机器人（`MachineLook` 那个镜头） | Big Tom. Wouldn't sleep without him till I was nine. | 大汤姆。我九岁以前，没它在身边就睡不着。 |
| 1-5 | `_run_machine`（按住 E 给小车充电） | Costs me a bit. Everything does, these days. | 得花掉我一点电。如今干什么都得花点力气。 |
| 1-6 | `_run_machine` 里跷跷板把机器人弹向书桌那一刻 | Here we go again— | 又来了—— |

> 后面几站（书桌、电视、厨房、晾衣绳、配电箱）还在改，定稿后再补进来。

---

## 需要队里定的

1. **人名和年份**：全家福是 **1953 年圣诞**（按八十来岁的老人算）。全家福贴图是 70 年代风格的服装，对不上的话可以改贴图，或者去掉年份（0-6 改成 "Christmas morning. Mum, Dad... and me..."）。
2. **★ 标的句子需要新镜头或事件**，尤其是开场看老人的镜头（0-2 到 0-4），这是整个设定的关键；还有 1-2b 站上小火车。
3. **独白怎么显示**：做成字幕（底部、斜体、白色，表示内心声音），还是旁边配一个小头像？等文本定了再说。
