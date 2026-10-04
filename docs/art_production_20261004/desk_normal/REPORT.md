# 正常书桌美术交付 — 2026-10-04

已创建 Stop2/DeskNormal，并在 room_art.gd 中局部注册 desk_normal_art.gd。没有改 room.gd、desk_maze 系列或 gen_room.py。

## 内容与氛围
12件GLB：连续旧木桌面、摊开的练习本、课本与书立、尺子与量角器、铅笔、小勺、草稿纸/圆规/糖纸、对折妈妈纸条、橡皮、铅笔盒、瓷杯和小闹钟；另有一片低于杯沿的冷茶表面。
橡皮和铅笔盒直接复用迷宫模型，按普通道具大小缩放；课本复用藏蓝、砖红、旧橄榄绿。妈妈纸条复用 prop_desk_folded_note_mom_note_colour.png，没有发光。
作业正对少年，普通暖黄台灯由现有场景提供，保留统一卧室的轻景深、浮尘和暗部。杯子做成圆润连续的空心瓷器；贴图为512固有色、磨损、格线和涂写，没有烘焙光影、新品牌或可读作业文字。普通道具没有青色互动提示。
桌面为70×140cm，顶面严格 .75m；北西角机器人落点周围留空，高物件放在东侧靠墙。课本最高17.2cm，低物件保持两条视线畅通。
所有新摆设无碰撞，随既有 room.gd 熄灯逻辑整组隐藏，迷宫显示。

## 必要验证
- slim_glb 已处理全部12件，512贴图。资源总三角面 7470，加冷茶表面仍远低于25,000。单件最高 1278。
- inbox.py check：188 files，0 failed。薄纸、尺子、小道具尺寸及桌面顶面原点的通用WARN符合用途，安装使用明确原点和缩放，没有自动重定位。
- 实际运行书桌入场段：face_clear=true，door_clear=true（逐三角面检测实际视线），no_collision=true，first_person=true，normal_hidden_after_blackout=true，maze_visible_after_blackout=true。
- 最终杯子修整后查看干净总览；face_clear、door_clear、no_collision仍为true。
- 按用户抓时间、少测试要求，没有运行完整通关自测；reached_goal_cell、note_found及完整迷宫路线本次未测。
- 导出 exit=0，exe 修改时间晚于导出开始。未另跑导出exe全流程。
- Godot退出仍有既有 material is null 清理日志，未改动与本次美术无关的玩法。

## 文件
build/win/JamTest_desk_normal.exe
shots/desk_normal/normal_overview.png：最终正常桌面。
shots/desk_normal/normal_pov_boy.png：实际入场第一人称（杯子修整前截图，其余摆设相同）。
shots/desk_normal/normal_hidden_dark.png：灯灭后正常桌面隐藏。
源模型 desk_normal.blend；构建脚本 build.py；接入脚本 desk_normal_art.gd；room_art.gd.before 保存注册前备份。

## 三角面
- desk_n_alarm_clock: 618
- desk_n_clutter: 758
- desk_n_eraser: 750
- desk_n_homework: 394
- desk_n_mug: 672
- desk_n_mum_note: 256
- desk_n_pencil: 684
- desk_n_pencil_case: 900
- desk_n_ruler_protractor: 820
- desk_n_spoon: 152
- desk_n_tabletop: 188
- desk_n_textbooks: 1278
