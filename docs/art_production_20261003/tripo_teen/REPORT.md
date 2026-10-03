# 坐姿少年 Tripo 接入

sitting human figure 3d model.glb 已替换 prop_seated_teen.glb。原约 79 万三角面，焊接 UV 边界后优化到 12000 三角面；纹理最大 512 px，粗糙度 .90，金属度 0。保留浅发、柔和五官、褪色砖红毛衣和橄榄色长裤。

脚底归零，坐面拟合 0.46 m，整体高 1.28 m，宽 .43 m。连续调整手臂到桌面，并向前调整上半身以避免椅背与袖子穿插，原场景位置及朝向不变。仍在俯视迷宫时隐藏、回第三人称后恢复。

test_bedroom_soft.gd 的全部检查通过：原碰撞几何保持、无额外美术碰撞、少年俯视隐藏及恢复通过；游戏画面已检查。build/win/JamTest_bedroom_tripo.exe 已重新导出并通过启动检查。

原文件保存在 originals/ 以及 inbox/source_archive/desktop_20261003/，旧自制版本在 backups/，最终 Blender 源文件、加工脚本和尺寸记录在 sources/。桌面副本通过 SHA256 校验后已删除。

至此床品、老人、少年和娃娃头四组 Tripo 模型均已接入。
