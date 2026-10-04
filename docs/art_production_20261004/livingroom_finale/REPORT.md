# 客厅滑索与终章美术交付 — 2026-10-04

## 已接入
26 个自制 GLB：衣物、衣夹、滑轮、天花固定盘、吊灯、吊盆、风铃、鸟笼；窗台、长窗框、卧室南窗框和外开窗扇；收音机与桌子；配电箱、拉杆、搁板与布包电线；圆润扶手椅临时美术；终章屋顶。天花板换为无烘焙光影的旧木板固有色贴图，卧室天花仍是单面 MeshInstance3D。

旧代理保留碰撞，仅隐藏外观；按 K=9 安装。窗台顶面 .90m、配电箱搁板顶面 1.06m 与原关卡一致。拉杆沿用原枢轴，灯由引擎控制。南窗双扇向外打开 80°，中央 .8×.6m 出口没有网格遮挡。未改动玩法、白模生成、室外城镇和声音。

## 尚未完成的正式素材
- 正式扶手椅：已接入用户提供的 Tripo 模型。
- People/OldManInArmchair：已隐藏原白模，接入用户提供的坐姿老人。
两者各一张照片式参考图，分别在 tripo_references/01_armchair/reference.png、tripo_references/02_old_man/reference.png；每个文件夹 README 写有尺寸及导出要求。老人以既有卧室人物为身份参考。提示词归档 prompts.json。

## 验证
- audit_whitebox：Stop5 无可见 CSG 白模，Stop6 只剩引擎灯例外；坐姿老人仍列为待替换。Shell 原结构代理仍在，相关外观以材质/模型处理。
- 滑索图形自测：stop5 所有布尔项 true，dodged=7、hops=3、bumps=0、walk_to_box_respawns=0。
- 终章图形自测：stop6 所有布尔项 true，ending_done=true，屋内灯 10/10，结束时长 45.5 秒。
- 窗外视角自测执行完成，已检查南窗、室外视角及结尾镜头。
- 专项网格检查 11 项全部 true：碰撞保留、窗台顶面/占地、搁板顶面、12 类滑索素材自动加载、南窗中央净空、旧南窗隐藏、单面天花、长窗深度、拉杆枢轴、两盏指示灯视线。窗口净空逐三角面检测，避免整窗框包围盒将空洞误算为实体。
- inbox：174 files，0 failed。衣物顶部原点、吊件小尺寸的通用 WARN 属于这类资源要求；滑索加载器直接使用这些原点，没有重置。
- 发布导出 exit=0，exe 修改时间晚于导出开始时间；导出程序 headless 启动 90 帧 exit=0。
- Godot 在场景退出时仍输出已有 material is null 清理错误；保留原日志，未在本次美术工作中修复。

## 文件
程序：build/win/JamTest_livingroom_finale.exe。F11 到滑索，F12 到配电箱。
截图：shots/sill_art、shots/finale_art、shots/views_art。review.png 为九张关键截图总览；review_breaker.png、review_south_window.png 为专项近景。
源模型：finale_source.blend；构建脚本 build.py；检查脚本 check.gd；完整源清单 manifest.json。

## 模型清单
- zip_garment_a.glb
- zip_garment_b.glb
- zip_garment_c.glb
- zip_garment_d.glb
- zip_garment_e.glb
- zip_peg.glb
- zip_rose.glb
- zip_pulley.glb
- zip_lamp.glb
- zip_plant.glb
- zip_chime.glb
- zip_cage.glb
- prop_finale_windowsill.glb
- prop_finale_long_window.glb
- prop_finale_bedroom_south_frame.glb
- prop_finale_window_leaf_left.glb
- prop_finale_window_leaf_right.glb
- prop_finale_radio_table.glb
- prop_finale_radio.glb
- prop_finale_breaker_box.glb
- prop_finale_breaker_lever.glb
- prop_finale_breaker_shelf.glb
- prop_finale_wire_drop.glb
- prop_finale_wall_wire.glb
- prop_finale_armchair_interim.glb
- prop_farmhouse_roof.glb

## Tripo 二次交付
两模型已归档 tripo_import；椅子 .8×.95×.899m，15790 三角面（为保留蕾丝和薄毯，高于原目标8k），老人头顶1.12m、15000三角面，均1024贴图。统一低金属度和粗糙布料，转向屋内。按模型脚底与坐姿将老人前移，避免腿陷入椅子；原碰撞代理尺寸和位置保留。只进行导入与实际摆放截图检查，不重跑通关自测。截图 shots/finale_art/chair_elder.png；新导出 build/win/JamTest_finale_models.exe，导出exit=0。
