# Tripo 返回模型第三批：入库和场景替换

日期：2026-10-03。桌面上的 7 个新 GLB 已全部接入正式项目，原文件保留。

| 桌面来源 | 游戏资源 | 尺寸/处理 |
|---|---|---|
| wooden chair 3d model.glb | prop_chair.glb | 座面标高 46cm、椅背 95cm；朝书桌，底面中心枢轴 |
| vintage round glasses 3d model.glb | prop_reading_glasses.glb | 折叠平放，12×3×1.8cm；镜片使用引擎透明材质 |
| glass tumbler 3d model.glb | prop_water_glass.glb | 直径7cm、高11cm；引擎透明玻璃，水面距杯底5.5cm |
| vintage medicine bottle 3d model.glb | prop_pill_bottle_a.glb | 琥珀色，直径4cm、高8cm；瓶盖顶面校平 |
| vintage bottle 3d model.glb | prop_pill_bottle_b.glb | 象牙白，直径3.6cm、高6.5cm；瓶盖顶面校平 |
| cardboard box 3d model.glb | prop_moving_box.glb | 箱体120×90×60cm、壁厚1.2cm；北盖28cm、东盖40cm，西侧外垂盖板按白模尺寸 |
| vintage brown box 3d model.glb | prop_shoebox.glb | 56×22×30cm；原模型盖顶顶点校平并校准完整平台占地 |

原药瓶、眼镜、水杯、椅子、鞋盒、箱壁和盖板的 CSG 碰撞保留，只有外观隐藏。新资源通过 tripo_structure_art.gd 安装，room_structure_art.gd 增加调用；没有重建 room.tscn 或改机关逻辑。运行时 Art_* 实例由30增加到37；--whitebox仍可查看白模。

纸箱原网格按墙/盖板直接拉伸会出现缝隙，因此按白模尺寸重建闭合圆角面板，转移 Tripo 的固有色与磨损纹理；转移不包含光照或 AO。纸箱不是未经处理的原网格。箱底使用深暗材质。玻璃杯原材质不透明，游戏内重新设置透明杯身、半杯水；透明物不遮挡月光。其余模型保留用户返回的贴图，统一降低金属度、提高木头/纸板粗糙度。

原文件总计165.25MB，游戏用七件合计2.71MB。原图缩到1024；箱板颜色图为768×512。面数：椅子6998、眼镜2997、水杯2998、药瓶各2999、纸箱864、鞋盒5499。经过 slim_glb 与保留命名节点的 slim_named_glb（gltfpack -kn），入库检查没有FAIL；眼镜1.8cm薄模型的通用高度WARN已确认是正常尺寸。inbox全目录69文件，0失败。

验证：

- 正式项目尺寸验收全部通过：药瓶/鞋盒顶高与占地、杯身尺寸和半杯水面、椅背高度、箱体八块面板尺寸、安装幂等、原CSG尺寸/变换/碰撞属性不变；无新增碰撞形状。见 project_verify.log。
- 第0/1站结构回归通过：头肩平台、相框、悬空书落入纸箱、火车、推块、小丑弹出与箱盖、出口弹射。37个实例全部加载。见 regression.log。
- 正式项目真实图形窗口以种子7验收第0/1/2站：所有布尔检查true，route_respawns=0，walk_stalls为空，60FPS。见 project_full_run.log 与 full_run_result.json。
- 已目视检查 shots/tripo_batch_03/ 的床头柜、透明杯/眼镜、箱体、鞋盒、椅子截图。截图为了观察颜色临时关闭雾/后处理并提高环境光，未改正常游戏打光。
- Windows Desktop成功导出 build/win/JamTest_models.exe，修改时间晚于导出开始，详见 export_result.json。当前有旧JamTest.exe运行，因此另存包含新模型的新包；既有窗口不会自动更新。

源文件、校准脚本、压缩前中间文件、检查报告与原安装脚本备份均在本目录。实际资源在 assets/models/props/，交付副本在 inbox/。

未测：新包完整通关、其余书桌种子的重复测试、电视及后续站点；这些逻辑没有改动。
