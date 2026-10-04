# 第4站厨房美术接入 · 2026-10-04

## 已完成

Blender 制作并接入 45 个 GLB。圆润厚实的微缩道具、米白旧漆、褪色木纹、少量钢面高光；只有互动标记与吸附钢面细边使用青色。贴图仅固有色及磨损，没有烘焙光影。

模型列表：
- prop_kitchen_counter_a.glb
- prop_kitchen_counter_b.glb
- prop_kitchen_counter_c.glb
- prop_kitchen_counter_e_n.glb
- prop_kitchen_counter_e_s.glb
- prop_kitchen_sink_rim_w.glb
- prop_kitchen_sink_rim_e.glb
- prop_kitchen_upper_cab_w.glb
- prop_kitchen_upper_cab_e.glb
- prop_kitchen_upper_cab_east.glb
- prop_kitchen_sink.glb
- prop_kitchen_stove.glb
- prop_kitchen_range_hood.glb
- prop_kitchen_hood_chimney.glb
- prop_kitchen_rail_n.glb
- prop_kitchen_rail_e.glb
- prop_kitchen_utensil_1.glb
- prop_kitchen_utensil_2.glb
- prop_kitchen_utensil_3.glb
- prop_kitchen_utensil_4.glb
- prop_kitchen_canned_goods.glb
- prop_kitchen_step_stool.glb
- prop_kitchen_chair.glb
- prop_kitchen_lunchbox.glb
- prop_kitchen_cereal_box.glb
- prop_kitchen_microwave.glb
- prop_kitchen_microwave_door.glb
- prop_kitchen_cutting_board.glb
- prop_kitchen_toaster.glb
- prop_kitchen_toaster_coils.glb
- prop_kitchen_spice_shelf.glb
- prop_kitchen_stock_pot.glb
- prop_kitchen_kettle.glb
- prop_kitchen_dish_rack.glb
- prop_kitchen_dish_pot.glb
- prop_kitchen_dish_lid.glb
- prop_kitchen_dish_bowl_a.glb
- prop_kitchen_dish_bowl_b.glb
- prop_kitchen_dish_plates.glb
- prop_kitchen_dish_ladle.glb
- prop_kitchen_sink_plug.glb
- prop_kitchen_faucet.glb
- prop_kitchen_daughter_mug.glb
- prop_kitchen_dining_table.glb
- prop_kitchen_flame.glb

微波炉门沿原东侧铰链旋转；砧板保留50×1×14cm及39cm推动距离；水池锅碗分别随原有中心枢轴倒塌。四件无碰撞挂勺装饰的枢轴移至1.30m挂钩，静止世界位置保持一致。原白模碰撞全部保留；新美术没有新增碰撞。

面包机加热丝为独立GLB，读取现有机关材质的发光强度。电水壶开关仍是独立引擎指示灯。灶火造型跟随原火焰缩放节点；积水改为半透明波纹材质，蒸汽改为柔和雾片，依旧随原机关显示和消失。灶火为主光，水面只有微弱冷蓝反射补光。女儿杯子有缺口、褪色儿童太阳/房子/牵手小人图案，朝玩家方向，带局部暖光。吊柜一扇门半开，露出盘子。

## Tripo已接入：3个

中年人物、米袋、吐司袋均已接入。最终尺寸、减面和验收见 [tripo_import/REPORT.md](tripo_import/REPORT.md)。以下保留原单视角参考图及规格归档：

- [中年人物](tripo_references/01_cook_middle_aged/reference.png)
- [米袋](tripo_references/02_rice_bag/reference.png)
- [吐司袋](tripo_references/03_bread_bag/reference.png)

内置 imagegen 生成参考图；全部原始提示词：[prompts.json](prompts.json)。图片是造型参考，站立尺寸仍需回库校准。可选冰箱、挂钟、日历和垃圾桶：本轮未制作。

## 实际验收

- tools/slim_glb.py 已运行；inbox check：check: 144 files, 0 failed, 0.3s。薄件（砧板、横杆、加热丝等）会触发通用“低于5cm”WARN，其米制尺寸符合关卡规格，无FAIL。
- 最终图形模式 --autotest --from=kitchen：全部布尔项 true，跨桥/到窗台均0次重生，穿过火焰0次灼伤。stop4完整输出见 selftest_final.log。
- 八级台阶实际落点（引擎单位）：0.99、1.98、2.97、3.96、4.95、6.03、7.20、8.19。末级落到台面上的1cm砧板（.91×9=8.19）；碰撞核对确认与接入前完全一致。
- test_kitchen_art.gd：17项全部 true，包括原碰撞变换、平台视觉高度±1cm、油烟机底面、东侧门铰链、挂钩枢轴及加热丝动态发光。
- 截图位置：shots/kitchen_art。检查 reveal_sink、board、hang、past_flares、rail、steam、collapse、mug、overview；另有 review_overview.png 与 review_mug.png 近景。
- 导出：build/win/JamTest_kitchen_art.exe；修改时间晚于记录的导出开始时间，见 export_check.json。启动烟雾检查退出码0。
- 最终运行在ROOMTEST输出之后，退出清理阶段出现 16 条 Godot “Parameter material is null”日志。运行期间未出现脚本/解析错误，验收结果全通过；退出材质清理日志仍未修复。
- 额外headless白模对照未作为验收依据：输入节奏与图形模式不同，跳跃落点未通过。正式验收只采用实际图形模式与碰撞变换核对，未声称白模headless自测通过。

## 修改范围

新增 scripts/kitchen_art.gd、scripts/kitchen_look.gd；scripts/room_art.gd 局部增加一行 install 调用。未修改 tools/gen_room.py、scripts/room.gd、scripts/tps_player.gd 或 components 玩法代码。

源文件 kitchen_source.blend、build.py、mug_paint.py 和 mug_albedo.png 已归档。按 F10 可以从体验版直接跳到厨房。


最新体验版：build/win/JamTest_kitchen_models.exe；三个新模型已替换，详见 tripo_import/REPORT.md。


最新体验版：build/win/JamTest_kitchen_models.exe；三个新模型已替换，详见 tripo_import/REPORT.md。
