# 卧室柔和造型与剩余替换交付

卧室、床头柜、纸箱和书桌范围内的剩余道具已全部替换。本次新增 6 个 GLB、7 个实例，重做此前 57 个自制 GLB 的圆角与表面法线，不使用 Tripo 次数。

新增：厚枕头、起伏被子、侧睡老人、写作业少年、瓷娃娃头（8 cm 与 6 cm 复用）、落地软垫。人物头部、头发与衣袖交界使用融合网格，布料使用曲面及包边；统一低饱和固有色、轻度磨损与简化五官，贴图没有光照或 AO。老人仅制作实际露出的头肩与手臂，避免被子穿插。

站立面保留原尺寸，圆角量控制在允许误差内；原白模碰撞、火车与积木动作、相框与门扇铰链、把手机关均保留。青色落脚互动标记和门缝亮光继续由原关卡控制。少年在俯视模式隐藏、第三人称恢复。

## 检查结果

- review_final.log：所有卧室道具已替换，未覆盖白模道具列表为空；碰撞几何完全保留；新增尺寸、重复安装与俯视隐藏全部通过。
- test_structure_art.gd.log：51 个结构美术实例、平台高度与机关动作全部通过。
- test_bedroom_finish.gd.log：床垫、玩具卡车、车轨、灯和门把手动作全部通过。
- desk_test_final.log：书桌随机池与其他回归种子的布局、预算、随机数和包络检查通过。
- playthrough_final.log：种子 7 图形模式完整关卡通过，route_respawns=0、walk_stalls=[]；错误日志为空。
- final_asset_checks.json：63 个新建或重做 GLB 的优化检查记录；单个模型均低于 25,000 三角面，色贴图最大 512 px，保留部件节点名。

## 文件

- assets/models/props/ 与 inbox/：已接入 GLB。
- shots/bedroom_soft/：游戏画面、总览及尺寸验证 JSON。
- 本目录 sources_*：Blender 源文件和尺寸/部件记录；build_soft.py 与 round_*.py 可重建。
- 本目录 backups/：被替换的旧模型及旧脚本、进度清单。
- build/win/JamTest_bedroom_soft.exe：新版体验包。

其他流程的 room.gd、gen_room.py 与 room.tscn 没有被本次重建或覆盖。
