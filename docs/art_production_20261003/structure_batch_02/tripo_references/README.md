# 新增 Tripo 参考图

7件物品，每件四张独立视图，总计28张。使用内置image_gen生成；这一步没有消耗Tripo模型次数。

|文件夹|物品|
|---|---|
|06_chair|旧木椅|
|07_reading_glasses|折叠老花镜|
|08_water_glass|半杯水的水杯|
|09_pill_bottle_a|琥珀药瓶|
|10_pill_bottle_b|象牙白药瓶|
|11_moving_box|旧搬家纸箱外观|
|12_shoebox|旧鞋盒外观|

上传每件的front.png、back.png、left.png、right.png，不上传four_views.png总图。每件目录的README注明目标尺寸。统一旧木头、旧黄铜和褪色纸板，普通道具不使用青色。玻璃和水返回后重设透明材质。纸箱与鞋盒返回后校准白模碰撞与平台尺寸。

本批不需要绑定或动画。GLB导出时保留内嵌色图。材质PBR可以保持关闭，去光照打开。参考图片本身的轻微渲染光照不可当作游戏纹理光照。

原始生成提示词和最终修正要求在PROMPTS_FULL.json；PROMPTS.json保留主要6件原始提示词。
