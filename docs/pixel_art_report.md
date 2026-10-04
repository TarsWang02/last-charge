# 电视关卡像素美术交付

本次只负责美术，未制作或调整音频。

## 正式素材

`assets/pixel/` 共 85 张 RGBA PNG，包含机器人与伸缩爪、史莱姆、蝙蝠、炮台与弹丸、骑士与剑、公主、电池、爱心；龙的头/张嘴/晕眩、身体、翅膀、脖颈、尾巴、尾尖和火球；地形贴块、塔顶、门、木板、平台、尖刺；天空、星星、远处城堡、山丘、公主塔；电池与龙血量界面、操作键帽、续命电池与投币口。

动画使用 `<名字>_<动作>_<序号>.png`：机器人待机/走路/跳跃/下落/受伤，伸爪、敌人动作、公主等待/挥手/获救、电池闪烁、火球滚动、木板晃动。全部尺寸见 `pixel_art_source/asset_manifest.json`。

所有素材遵循原生像素网格、最近邻显示、二值透明度、深色轮廓与统一色板；青色保留给机器人、电池和对应界面。龙身体采用 ImageGen 制作形象参考，再转换到 48×31 网格及六色板，原图与可复现的像素素材生成脚本保存在 `pixel_art_source/`。

需求清单中的贴图均已替换。ASCII 后备图仍保留以兼容缺失资源情况；攻击预警、晕眩星星、粒子、发光和颜色褪去仍由现有绘制逻辑完成，属于效果层。未新增玩法或音效。

## 验证

- 导入成功；85 张素材尺寸、RGBA、二值透明度与青色用途检查通过。
- 图形运行检查：320×240、最近邻、动画序列加载均通过。
- 完整电视站自动流程实际运行通过：`stop3` 无 false，`princess_reached=true`、`boss_beaten=true`、`boss_phase2_seen=true`、`left_tv=true`。
- 已人工查看开场、恶龙两个阶段及颜色褪去的 CRT 截图；最后微调远处城堡窗户位置后，补查了原生像素关键状态截图。
- 所有原有非美术函数和常量与改动前逐项核对一致。只添加贴图绘制工具并修改画面绘制。
- Windows 导出成功，EXE 修改时间晚于导出开始时间；导出版本房间启动检查通过。导出时间证据见 `pixel_art_source/export_check.json`。

## 路径

- 体验版本：`build/win/JamTest.exe`
- 实际流程截图：`shots/pixel_check/room_s3_in_tv.png`、`room_s3_boss.png`、`room_s3_boss_phase2.png`、`room_s3_colour_drains.png`
- 原生画面检查：`shots/pixel_art_review/`
- 素材总览：`pixel_art_source/contact.png`
- 自测结果、素材检查、实现差异和日志：`pixel_art_source/`

## 追加修改：城堡 ANU 徽章
远景城堡中央塔楼加入低饱和暖金色盾徽和 ANU 字样，使用原生像素绘制；参考 https://marketing-pages.anu.edu.au/_anu/4/images/logos/anu_logo_print.png 。已运行关键画面检查并重新导出 Windows 版本。仅更改背景贴图。
