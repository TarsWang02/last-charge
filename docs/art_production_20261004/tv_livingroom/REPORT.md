# 第3站：客厅电视 3D 美术交付

仅制作电视外面的3D美术，无音频工作。延续圆润、厚实、哑光、低饱和的旧玩具与微缩模型风格；固有色和轻微表面纹理不包含烘焙光影。电视冷蓝照明，时光盒子打开时暖琥珀。

## 已接入

原有 12 件结构模型均已接入，另已新增正式沙发与青年。结构模型包括：显像管电视、木皮电视柜、虚构游戏机、插线板、引路电线、游戏盒、杂志堆、低音炮、落地音箱、时光盒身、独立铰链盒盖、盒内物品。

电视采用空心屏幕开口，无 Glass 遮挡。游戏画面继续使用原有的平面、SubViewport 和 CRT 效果。旧白模只替换为透明材质，碰撞和原节点保留。盒盖直接挂在现有 TimeBoxLid 枢轴下，随原机关打开。盒内放无文字的儿童蜡笔画、孩子与铁皮机器人的抽象小照片、三颗弹珠。儿童画由 imagegen 制作平面固有色参考，缩到512贴图并嵌入 GLB。

补少量随 TVGlow 同步淡出的局部蓝色反射光，阴影阻挡穿墙；无新增青色普通道具。新增一块无碰撞的暗色地毯，位于通道和出口落点外。

## Tripo 正式模型

Tripo 已制作青年与沙发两件，其余结构由 Blender 制作。

| 项目 | 当前状态 | 交付要求 |
|---|---|---|
| 布艺双人沙发 | 已替换为 Tripo 正式沙发，8997 三角面、1024贴图，座面校准到.42m | 宽1.60m、总深.85m、靠背.85m、座面.42m，扶手在宽度内；场景西缘x≥.65 |
| 坐着玩游戏的青年 | 已替换为 Tripo 青年，13998 三角面、1024贴图；脚底落地，头顶1.20m，面朝电视 | 浅棕乱发、暖浅肤色、偏抽象脸；同一少年长大到22岁，卫衣牛仔裤，前倾、双手握手柄；无椅子无骨骼 |
| 有线手柄 | 使用青年自带手柄，已接线到游戏机；自制手柄 GLB 留作备选 | 两按钮与十字键，无商标；参考人物可自带手柄，届时选择保留一套 |

两件复杂模型各有 `front.png`、`back.png`、`left.png`、`right.png` 四张独立参考图，不需要上传总览拼图：

- `tripo_references/01_seated_young_man/`
- `tripo_references/02_sofa/`

每个文件夹的 README 含尺寸、面数和导出要求。GLB，Y向上、原模型正面+Z；入场时沙发和青年朝北旋转。无品牌，无可读文字，避免高饱和青色。人物不必做精细毛孔或清晰五官。

## 实现范围

新增 `scripts/tv_livingroom_art.gd`、`scripts/tv_livingroom_look.gd`。`scripts/room_art.gd` 仅加一行调用。`tools/gen_room.py`、`scripts/room.gd`、`scripts/tv_game.gd`、`scripts/tv_screen.gd`、`scenes/room.tscn` 本次美术工作未修改。制作期间其中三个文件出现同时进行的更新，已保留，最终验收按最新文件补跑；实际测试版本哈希见 latest_test_hashes.json。

正式 GLB 在 `assets/models/props/`，交付副本在 `inbox/`，未执行 inbox ingest，避免该工具把多个 prop 文件覆盖到同一个 prop.glb。全部经 slim_glb 检查和优化后按原文件名入库。小道具大多500–3000三角面，电视与柜子在10000以内；细电线仅192三角面，不添加无意义几何。薄纸、盒盖、手柄高度低于通用检测器的5cm阈值时会 WARN，这是正确米制尺寸，无 FAIL。

## 验证与体验

本轮正式沙发与青年接入的实测、原件归档与导出证据见 tripo_import/README.md 和 tripo_import/validation.json；早期结构模型记录见 VALIDATION.md。

截图：`shots/tv_art/` 为实际完整流程；`shots/tv_art_review/` 为电视正面、台阶及打开时光盒子的美术近景。

Windows体验版：`build/win/JamTest_tv_livingroom_models.exe`。最终覆盖 JamTest.exe 时临时文件重命名失败，已另存独立体验版本；原有运行中的版本未关闭。

源文件：`build_livingroom.py`、`livingroom_source.blend`、`crayon_albedo.png`、`model_manifest.json`。生成脚本在本目录运行会输出 delivery/；它不会修改玩法代码。
