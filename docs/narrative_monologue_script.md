# Last Charge：独白脚本（草稿 v2）

> **设定**：老人睡着了，灵魂进了他小时候那只铁皮机器人里。全程是**他的第一人称内心独白**：一开始不知道自己在哪、是谁，一路认出自己的家、自己的一辈子，最后把剩下的一点电交出去，让屋子亮起来。
> **口吻**：澳洲乡下老头，八十来岁。话少、朴实，带点自嘲，不煽情。澳洲用词点到为止（Mum、reckon、struth、righto、old girl），不要满屏 "mate"。
> **人设**（可改）：1946 年生；妻子 **Marg**（Margaret，已去世）；女儿 **Lucy**；全家福是 **1953 年圣诞**，他 7 岁，手里抱的就是这只机器人（50 年代正好是铁皮机器人流行的年代）。
> **格式**：游戏里用英文，中文是给队友对照的。每句尽量控制在一行以内。"触发"一栏写的是 `room.gd` 里已有的函数或区域，方便之后接线；标 ★ 的是**目前没有对应镜头或事件、需要新加**的。
> **配音**：每句一个文件，`assets/audio/vo/vo_s<站号>_<两位句号>.ogg`（例：0-1 → `vo_s0_01.ogg`，1-2b → `vo_s1_02b.ogg`，5-16 → `vo_s5_16.ogg`）。由 `tools/vo/gen_vo.py` 生成，读法（语气词、语速、音调）也在那里改。妈妈的纸条是给玩家读的，不配音。

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

## 第 4 站 · 厨房（为人父）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 4-1 | `_after_tv_looks`（被吐出电视，镜头找到灶台的火光） | Who left the stove on? | 谁没关灶台？ |
| 4-2 | ★ 看清灶台前定格的中年男人（`FatherHead`） | ...Ah. Me again. Forty-odd, in Marg's apron. | ……啊，又是我。四十出头，系着 Marg 的围裙。 |
| 4-3 | 紧接 4-2 | Pancakes every Sunday. Burnt, every Sunday. She never said a word. | 每个礼拜天做煎饼，每个礼拜天都烤糊。她从来没说过一句。 |
| 4-4 | `_kitchen_reveal`（镜头扫过水龙头和满地的水） | And the tap's running. Marg'd have my hide. | 水龙头也开着。让 Marg 看见，非扒了我的皮不可。 |
| 4-5 | `_kitchen_reveal`（镜头看到远处的窗台） | The windowsill. That'll take me round to the breaker. | 窗台。顺着它能绕到配电箱。 |
| 4-6 | ★ 第一次碰到水、短路回检查点 | Water and me don't mix any more. | 我现在可沾不得水了。 |
| 4-7 | ★ 开始爬杂货堆和椅子 | Sunday's shopping. Never did get put away. | 礼拜天买的东西，一直没收起来。 |
| 4-8 | `_microwave`（炉门把砧板推过缺口） | Ha. Never thought I'd thank a microwave. | 哈，没想到有一天会感谢一台微波炉。 |
| 4-9 | `_toaster`（跳进烤面包机的槽里） | Hope I don't come out burnt. | 但愿出来的时候别烤糊了。 |
| 4-10 | `_toaster`（被弹到调料架上） | Like toast. | 跟吐司一样。 |
| 4-11 | ★ 第一次出现电磁铁提示（右键） | Got a magnet in me, have I? Handy. | 我身上还有块磁铁？挺管用。 |
| 4-12 | ★ 吊在抽油烟机下，第一次看到灶火窜起 | That stove's always had a temper. | 这灶台脾气一直不小。 |
| 4-13 | `_kettle`（给水壶通电） | Kettle's on. Best idea I've had all night. | 烧上水了。今晚最好的主意。 |
| 4-14 | ★ 第一次被蒸汽托起来 | Up we go— | 起—— |
| 4-15 | `_sink_collapse`（碗碟一路倒下来） | ...That'll be the dishes. | ……碗碟全完了。 |
| 4-16 | `_drain_flood`（塞子弹开，积水退去） | Well. That's one way to do the washing up. | 行吧，这也算是洗过碗了。 |
| 4-17 | `_ring_mug`（敲响女儿的杯子） | Lucy's mug. She painted it when she was five. | Lucy 的杯子，她五岁时画的。 |
| 4-18 | 紧接，镜头看向灶台前的自己 | Still rings the same. She doesn't ring as often. | 敲起来声音还跟从前一样。只是她现在不常打电话来了。 |

## 第 5 站 · 晾衣绳（晚年）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 5-1 | ★ 敲完杯子，镜头看到杯子旁的衣架，和横穿整个客厅的晾衣绳 | A coat hanger... and the line runs right across the room. | 一个衣架……晾衣绳一直横穿整个客厅。 |
| 5-2 | 紧接 5-1（自言自语） | Maybe... I could ride these over to the breaker. | 也许……我能借着这些到配电箱那边去。 |
| 5-3 | `_zipline_grab`（按 E 抓住衣架） | Marg's clothesline. Strung it through the house when her knees went. | Marg 的晾衣绳。她膝盖不行以后，我把它拉进了屋里。 |
| 5-4 | 紧接，开始滑行（致敬 Apex 里 Pathfinder 爱滑索的梗） | Who's ready to fly on the zipline? I am! | 谁准备好坐滑索飞一把了？我！ |
| 5-5 | ★ 第一次需要左右摆（A / D）躲开吊着的东西 | Lean, you old goat. Lean! | 往边上偏，你个老东西，偏啊！ |
| 5-6 | ★ 第一次被衣夹卡住（`clacked`），提示跳过 | Hop the pegs. Hup! | 跳过衣夹，嘿！ |
| 5-7 | ★ 第一次冲破晾着的衣服 | Sorry, love. | 对不住了，老婆。 |
| 5-8 | ★ 撞上吊灯 / 鸟笼等（`clacked`） | Never did like that lamp. | 那盏灯我从来就不喜欢。 |
| 5-9 | `_slow_look("in")`（慢镜头回头看屋里） | Every bit of this place... I could walk it with my eyes shut. | 这屋子的每个角落……我闭着眼都能走。 |
| 5-10 | 紧接，镜头掠过扶手椅 | That chair's got my shape in it. | 那把椅子，都坐出我的形状了。 |
| 5-11 | ★ 窗外小镇的灯一片片熄灭 | Whole town's going dark. | 整个镇子都黑了。 |
| 5-12 | `_slow_look("out")`（慢镜头望向窗外的小镇） | Lived here all my life. Never once saw it from up here. | 在这儿住了一辈子，从来没从这么高的地方看过它。 |
| 5-13 | 紧接，电池只剩最后一格（红） | ...Not much left in me now. | ……我没剩多少电了。 |
| 5-14 | `_zipline_end`（落到配电箱旁的窗台，切回第三人称） | There's the breaker. | 配电箱就在那儿。 |
| 5-15 | 紧接 5-14 | Nearly there. | 快到了。 |
| 5-16 | 紧接 5-15（落地后） | Losing isn't fun. That's why I don't do it. | 输可不好玩，所以我从来不输。 |

> 第 6 站（配电箱）待写。

---

## 需要队里定的

1. **人名和年份**：全家福是 **1953 年圣诞**（按八十来岁的老人算）。全家福贴图是 70 年代风格的服装，对不上的话可以改贴图，或者去掉年份（0-6 改成 "Christmas morning. Mum, Dad... and me..."）。
2. **★ 标的句子需要新镜头或事件**：开场看老人（0-2 到 0-4，整个设定的关键）、站上小火车（1-2b）、点灯 / 掉缝 / 推橡皮 / 填洞（2-4、2-7 到 2-9）、妈妈纸条的交互界面（2-10）、被动吸进电视（3-5，现在是按 E）、像素游戏里的各个首次事件（3-6 到 3-12）、厨房的看清自己 / 碰水 / 爬杂货 / 磁铁 / 灶火 / 蒸汽（4-2、4-6、4-7、4-11、4-12、4-14）、晾衣绳上的首次摆动 / 衣夹 / 衣服 / 碰撞 / 小镇熄灯（5-1、5-5 到 5-8、5-11）。
3. **独白怎么显示**：做成字幕（底部、斜体、白色，表示内心声音），还是旁边配一个小头像？等文本定了再说。
