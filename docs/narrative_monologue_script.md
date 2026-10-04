# Last Charge：独白脚本（草稿 v2）

> **设定**：老人睡着了，灵魂进了他小时候那只铁皮机器人里。全程是**他的第一人称内心独白**：一开始不知道自己在哪、是谁，一路认出自己的家、自己的一辈子，最后把剩下的一点电交出去，让屋子亮起来。
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

## 第 2 站 · 书桌（少年）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 2-1 | `_enter_desk`（落到桌上，看清写作业的少年；呼应 0-5） | Hang on... isn't that me? | 等等……那不是我吗？ |
| 2-2 | 紧接 2-1 | Why am I so young? Can't be more than fifteen. | 我怎么这么年轻？顶多十五岁。 |
| 2-3 | `_enter_desk`（台灯熄灭，四周一片漆黑） | Struth. Black as pitch. Can't see a blessed thing. | 要命，黑得跟锅底似的，啥也看不见。 |
| 2-4 | ★ 第一次按 E 点亮旧灯（`components/reveal_light.gd`） | Every bit of light costs me now. | 现在每一点光，都得拿我的电来换。 |
| 2-5 | 紧接 2-4（灯亮了，看清迷宫） | My desk was always a maze. Mum reckoned I'd lose my own head in it. | 我这张桌子一直乱得跟迷宫似的。妈说我迟早连自己的脑袋都能在上面弄丢。 |
| 2-6 | 紧接 2-5（起点那盏灯照出终点：门把手） | Door's right down the far end. Course it is. | 门在最远那头。可不是嘛。 |
| 2-7 | ★ 第一次掉进桌缝、被送回检查点 | Mind the cracks. Always did fall through them. | 小心那些缝。我从小就老掉进去。 |
| 2-8 | ★ 第一次推动橡皮（`components/pushable.gd`） | Mum always said that rubber'd come in handy. | 妈总说这块橡皮迟早用得上。 |
| 2-9 | ★ 橡皮掉进洞里、填平（`components/hole_fill.gd`） | There. Good as a bridge. | 好了，跟座桥一样。 |
| 2-10 | ★ 走近妈妈的纸条，提示 `E  Read`；按 E 纸条在屏幕中央展开（手写体、泛黄纸、背景压暗、暂停），再按 E 收起 | 见下方"妈妈的纸条" | |
| 2-11 | 收起纸条后 | "Back soon." She always was. | "马上回来。"她每次都说到做到。 |
| 2-12 | 紧接 2-11 | Till the one time she wasn't. | 只有那一次没有。 |
| 2-13 | `_open_door`（门开，镜头找到配电箱） | The breaker. That's what's gone. | 配电箱。是它跳闸了。 |
| 2-14 | 紧接，镜头转向电视的蓝光 | ...Telly's still going, though. | ……可电视还亮着。 |

**妈妈的纸条**（交互文本，手写体）

| English | 中文 |
|---|---|
| Love — | 宝贝—— |
| Gone to help Mrs Kelly with the calving. Back soon. | 去帮凯利太太接生小牛了，马上回来。 |
| Tea's in the oven. Finish your maths. | 饭在烤箱里。把数学写完。 |
| P.S. Your robot's on the windowsill. Stop leaving him out in the rain. | 又及：你的机器人在窗台上。别再把它丢在外面淋雨了。 |
| — Mum x | ——妈 x |

实现：现在纸条是靠近自动触发（`room.gd` 的 `note_found`），要改成 Interactable + 一个纸条展开界面。纸条上的 "Back soon"、"Finish your maths" 与现有贴图 `prop_desk_folded_note_mom_note_colour.png` 一致，美术不用改。

## 第 3 站 · 电视（青年）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 3-1 | 落到客厅地板上，看到电视前坐着的青年 | There I am again. | 又是我。 |
| 3-2 | 紧接 3-1 | Twenty-two. Hair down to my collar. Thought I was something. | 二十二岁，头发留到领口。那时候还觉得自己挺了不起。 |
| 3-3 | ★ 第一次跳上游戏盒 / 杂志堆 | Every game I ever owned. Never chucked one out. | 我买过的每一盘游戏，一盘都没扔。 |
| 3-4 | ★ 爬上电视柜，站到屏幕前 | Haven't played this since... well. Since. | 好久没玩这个了，自从……唉，自从那以后。 |
| 3-5 | `_enter_tv`（★ 改成被动：靠近屏幕就被吸进去，不再按 E） | Oi— what's— it's pulling me in—! | 哎——怎么——它在把我往里吸——！ |
| 3-6 | ★ 进入游戏，第 1 屏开头 | Well, I'll be. I'm in the game. | 嘿，我进游戏里来了。 |
| 3-7 | ★ 第 1 屏，低矮隧道里的史莱姆（跳不过，要用爪子：J / 左键） | Can't hop this one. Give it a whack. | 这个跳不过去，给它一下子。 |
| 3-8 | ★ 第一次被打中，或掉坑"投币"续关 | Twenty cents a go, back then. Now it's me paying. | 那时候一局两毛钱。现在得拿我自己来付。 |
| 3-9 | ★ 第一次捡到像素电池 | Ha. They've got batteries in here too. | 哈，这里头也有电池。 |
| 3-10 | ★ 第 3 屏，持盾骑士出现（等他出招、躲开、再反击） | Let him have a go first. Then get him. | 让他先出手，再收拾他。 |
| 3-11 | ★ 恶龙出现 | Never could beat this one. Not once. | 这一关我从来没打过去，一次都没有。 |
| 3-12 | ★ 恶龙进入第二阶段（咆哮） | Oh, now he's cranky. | 哟，这下它火了。 |
| 3-13 | `_tv_finale`（救到公主，画面开始褪色） | Got there in the end. Only took me sixty years. | 总算打通了。也就花了六十年。 |
| 3-14 | `_tv_finale` 里电视自己关掉（呼应 2-14） | ...And there goes the telly. | ……电视也没电了。 |
| 3-15 | `_exit_tv` 后，看到旁边的时光盒 | My old time box. | 我的时光盒。 |
| 3-16 | `_open_time_box`（打开时光盒） | My drawing. Me and the robot, beating the dragon. | 我的画。我和机器人，一起打败恶龙。 |
| 3-17 | 紧接 3-16 | Thought I'd be a hero. Ended up a farmer. Not a bad trade. | 那时候以为自己会当英雄，后来当了农民。也不亏。 |

> 第 4–6 站（厨房、晾衣绳、配电箱）待写。

---

## 需要队里定的

1. **人名和年份**：全家福是 **1953 年圣诞**（按八十来岁的老人算）。全家福贴图是 70 年代风格的服装，对不上的话可以改贴图，或者去掉年份（0-6 改成 "Christmas morning. Mum, Dad... and me..."）。
2. **★ 标的句子需要新镜头或事件**：开场看老人（0-2 到 0-4，整个设定的关键）、站上小火车（1-2b）、点灯 / 掉缝 / 推橡皮 / 填洞（2-4、2-7 到 2-9）、妈妈纸条的交互界面（2-10）、被动吸进电视（3-5，现在是按 E）、像素游戏里的各个首次事件（3-6 到 3-12）。
3. **独白怎么显示**：做成字幕（底部、斜体、白色，表示内心声音），还是旁边配一个小头像？等文本定了再说。
