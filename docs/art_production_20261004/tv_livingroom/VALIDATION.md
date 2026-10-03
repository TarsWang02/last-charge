# 实测验收

- 最终素材与灯光版本实际运行电视站自动流程通过；stop3 无 false，princess_reached、boss_beaten、left_tv、time_box_open、tv_switched_off 均为 true。
- 第一轮完整流程台阶高度正常。最后一轮完整流程的首级自动跳跃曾记录0.00，其余落点正常；按最新场景独立补跑五级跳跃，实测0.81 / 1.71 / 2.61 / 3.50 / 4.50。音箱落点0.01引擎单位差异约1.1mm，满足±1cm真实米制误差。首次0.00的具体自动流程原因未定位，未改玩法代码掩盖结果。
- 模型实际顶面与原碰撞检查全部通过；屏幕开口无遮挡；盒盖保留原枢轴并随原节点旋转。
- inbox check：96文件、0 FAIL。薄道具通用高度检测产生的 WARN 为正确真实尺寸。
- 实际查看门口电视蓝光、屏幕前、推入屏幕、时光盒子流程截图，并查看电视正面、台阶及盒内蜡笔画近景。
- 导出成功，EXE 修改时间晚于导出开始时间；导出版本房间 headless 启动检查成功。
- 本次美术工作未修改5个保护文件。制作及验证期间 gen_room.py、room.gd、room.tscn 持续出现同时进行的更新，已保留。latest_test_hashes.json 记录最后一次完整流程启动前的版本；运行中继续变化的文件记录在 validation_result.json，未将其错误声称为全部哈希不变。最新场景的美术碰撞检查与独立五级跳跃通过，未测试其他人新改动的所有玩法。

实际流程截图：C:/Users/Thunder/jam-test/shots/tv_art/

近景截图：C:/Users/Thunder/jam-test/shots/tv_art_review/

沙发正式 Tripo 模型、青年正式 Tripo 模型及其手柄最终位置尚未收到，未测。当前沙发为圆润临时造型，青年仍是原白模。

## 正式人物与沙发已接入
当前两件 Tripo 成品均已收到并替换，人物自带手柄已接线。新一轮完整自测首级台阶落点0.81，其余落点也正常，stop3无false。最新证据见 tripo_import/validation.json，本节更新替代此前未收到的状态。
