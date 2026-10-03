# Tripo 最后一批入库与桌面整理

已找到并接入 3 个新原始文件：padded floor mattress 3d model.glb、sleeping elderly man 3d model.glb、antique doll head 3d model.glb。床品拆为枕头和被子，最终接入 4 个 GLB；娃娃头复用为 8 cm 与 6 cm 两个实例。少年新文件未在桌面或下载目录找到，当前继续使用已完成的自制坐姿少年。

## 加工与接入

原文件约 78–80 万三角面，焊接 UV 边界、减面后保留柔和造型与颜色贴图。枕头 2710、被子 13289、老人 16000、娃娃头 5120 三角面；全部纹理最大 512 px。床品按真实结构分开，枕头仍为 1.10 × 0.35 × 0.12 m、顶面 0.67 m，被子占地 1.26 × 1.40 m，老人头部对齐枕头。老人原点是床上的定位锚点而非脚底，因此检查工具的负 min_y 警告属于预期结果，不会自动重新居中。保留原床垫、碰撞和机关，不修改少年俯视隐藏逻辑。

运行 test_bedroom_soft.gd 的全部尺寸、碰撞和接入检查通过；结构平台及机关回归通过。导出 build/win/JamTest_bedroom_tripo.exe 并完成启动检查。

## 文件管理

桌面的全部 17 个项目 GLB 已逐个复制到 inbox/source_archive/desktop_20261003/，校验 SHA256 一致后删除桌面副本。没有删除其他桌面文件。manifest.json 保存原路径、归档路径、大小、哈希和清理状态。

本批 3 个原始文件另存本目录 originals/；旧自制模型保存在 backups/，Blender 源文件与尺寸记录放 sources/。正式游戏资源仍在 assets/models/props/，优化后的交付副本在 inbox/。
