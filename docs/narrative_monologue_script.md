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
| 2-1 | `_enter_desk`（落到桌上，看清写作业的少年；呼应 0-5） | ...It's me. Fifteen, and still not done with my maths. | ……是我。十五岁，数学作业还没写完。 |
| 2-1b | 紧接 2-1（台灯熄灭，镜头升到俯视、迷宫出现） | My desk was always a maze. Mum reckoned I'd lose my own head in it. | 我这张桌子一直乱得跟迷宫似的。妈说我迟早连自己的脑袋都能在上面弄丢。 |
| 2-2 | 走到妈妈的纸条（`mom_note`） | "Back soon." She always was. | "马上回来。"她每次都说到做到。 |
| 2-3 | 紧接 2-2 | Till the one time she wasn't. | 只有那一次没有。 |
| 2-4 | `_open_door`（门开，镜头找到配电箱） | The breaker. That's what's gone. | 配电箱。是它跳闸了。 |
| 2-5 | 紧接，镜头转向电视的蓝光 | ...Telly's still going, though. | ……可电视还亮着。 |

## 第 3 站 · 电视（青年）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 3-1 | ★ 爬上电视柜 | Spent half my twenties in front of this thing. | 我二十来岁那几年，一半时间都耗在这玩意儿跟前。 |
| 3-2 | `_enter_tv`（按 E 钻进屏幕） | Here goes nothing. | 豁出去了。 |
| 3-3 | ★ 进入游戏后（第 1 屏开头） | Knights, dragons, a princess. I drew this when I was seven. | 骑士、恶龙、公主。这是我七岁时画的。 |
| 3-4 | `_tv_finale`（救到公主，画面褪色） | Got there in the end. Only took me sixty years. | 总算救到了。也就花了六十年。 |
| 3-5 | `_open_time_box`（打开时光盒） | My drawing. Me and the robot, beating the dragon. | 我的画。我和机器人，一起打败恶龙。 |
| 3-6 | 紧接 3-5 | Thought I'd be a hero. Ended up a farmer. Not a bad trade. | 那时候以为自己会当英雄，后来当了农民。也不亏。 |

## 第 4 站 · 厨房（为人父）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 4-1 | `_after_tv_looks`（镜头找到灶台的火光） | Who left the stove on? | 谁没关灶台？ |
| 4-2 | `_kitchen_reveal`（满地的水、溢出的水槽） | ...And the tap. Marg'd have my hide. | ……水龙头也没关。让 Marg 看见，非扒了我的皮不可。 |
| 4-3 | ★ 第一次看清灶台前定格的父亲 | Look at him. Pancakes every Sunday. Burnt, every Sunday. | 看看他。每个礼拜天都做煎饼，每个礼拜天都烤糊。 |
| 4-4 | 第一次碰到水、短路回检查点 | Water and me don't mix any more. | 我现在可沾不得水了。 |
| 4-5 | `_sink_collapse` 之后（水退了） | That's sorted, then. | 这下好了。 |
| 4-6 | `_ring_mug`（敲响女儿的杯子） | Lucy's mug. She painted it when she was five. | Lucy 的杯子，她五岁时画的。 |
| 4-7 | 紧接 4-6（镜头看向父亲） | Still rings the same. She doesn't ring as often. | 敲起来声音还跟从前一样。只是她现在不常打电话来了。 |

## 第 5 站 · 晾衣绳（晚年）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 5-1 | `_zipline_grab`（抓住衣架） | Hold on to your hat. | 抓稳了。 |
| 5-2 | ★ 窗外小镇的灯开始一片片熄灭 | Whole town's going dark. | 整个镇子都黑了。 |
| 5-3 | `_slow_look("out")`（慢镜头看窗外） | Lived here all my life. Never once saw it from up here. | 在这儿住了一辈子，从来没从这么高的地方看过它。 |
| 5-4 | `_slow_look("in")`（慢镜头看屋里，老人在扶手椅里） | That chair's got my shape in it. | 那把椅子，都坐出我的形状了。 |
| 5-5 | `_zipline_end`（落在窗台上，电池只剩最后一格红） | Not much left in me now. | 我没剩多少电了。 |

## 第 6 站 · 配电箱（结局）

| # | 触发 | English | 中文 |
|---|---|---|---|
| 6-1 | 走到配电箱下面 | Righto. One last job. | 好了，最后一件活儿。 |
| 6-2 | `_breaker_progress` 约 30% | Come on, old girl... | 加把劲，老伙计…… |
| 6-3 | `_breaker_progress` 约 80% | Take the lot. I won't be needing it. | 全拿去吧，我用不着了。 |
| 6-4 | `_breaker_done`（咔哒，灯一盏盏亮起） | ...There. | ……好了。 |
| 6-5 | `_ending_camera` 停在熟睡的老人那一段 | Sleep tight, old fella. | 好好睡吧，老家伙。 |
| 6-6 | `_ending_camera` 升到小镇上空、只有这栋房子亮着 | Lucy'll see the light from the road. She'll know I'm home. | Lucy 从路上就能看见这盏灯。她会知道我在家。 |
| — | 标题 | LAST CHARGE | |

---

## 需要队里定的

1. **人名和年份**：Marg（妻子）、Lucy（女儿）、1953 年圣诞。全家福贴图是 70 年代风格的服装，如果要保留"八十岁老人"的设定，**照片贴图和年份会对不上**。可以改贴图，也可以不写年份（0-6 改成 "Christmas morning. Mum, Dad... and me..."）。
2. **★ 标的句子需要新镜头或事件**，尤其是开场看老人的镜头（0-2 到 0-4），这是整个设定的关键。
3. **结局要不要说话**：6-5 和 6-6 会打破现在的无字一镜到底。我觉得这两句值得加，但也可以只留 6-4 "...There." 一句。
4. **独白怎么显示**：做成字幕（底部、斜体、白色，表示内心声音），还是旁边配一个小头像？等文本定了再说。
