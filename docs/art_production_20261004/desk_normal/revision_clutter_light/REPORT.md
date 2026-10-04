# 正常书桌：增加杂乱与台灯调整

复用原有素材新增15处摆放：两组不同角度的散纸与圆规、两支短铅笔、一本翻开的书、三团纸、三枚回形针、四块削笔屑。物件不加碰撞，继续由 DeskNormal 整组隐藏，落点和两条视线保持通畅。

原 DeskLampGlow 保留原能量属性给玩法代码控制，但灯光层设为0，不再向四周铺光。新增灯罩下方的柔和聚光灯朝作业与桌面照射，另有弱桌面反光；墙上只留少量间接暖色。灯光、灯泡发光与台灯浮尘随原能源状态关闭，结尾恢复供电时灯具可重新显示。未改 room.gd 或迷宫玩法。

必要检查：face_clear、door_clear、no_collision、downlight_on、downlight_off、bulb_off 全true。查看实际正常桌面截图；未重跑完整通关。既有场景退出材质清理错误仍记录于 review.log。

导出 build/win/JamTest_desk_normal_messy.exe，exit=0，修改时间晚于导出开始。
预览 preview.png；改前接入脚本 desk_normal_art.gd.before。
