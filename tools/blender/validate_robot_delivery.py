from pathlib import Path
import subprocess,shutil,json,time
root=Path(r'C:\Users\Thunder\jam-test');work=root/'tools/blender'
cmd=[str(root/'tools/.venv/Scripts/python.exe'),str(root/'tools/inbox.py'),'check']
t=time.perf_counter();r=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8',errors='replace');(work/'inbox_check.log').write_text(r.stdout+'\n'+r.stderr,encoding='utf-8');print(r.stdout,r.stderr);checktime=time.perf_counter()-t
# Isolated Godot project: imports can create .import files, so keep them outside protected assets/.
v=work/'godot_validation';v.mkdir(exist_ok=True);(v/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Robot import validation"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8');shutil.copy2(root/'inbox/robot_parts.glb',v/'robot_parts.glb')
cmd2=[r'D:\Godot_v4.7.2-stable_win64_console.exe','--headless','--path',str(v),'--import'];t=time.perf_counter();g=subprocess.run(cmd2,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=180);godottime=time.perf_counter()-t;log=g.stdout+'\n'+g.stderr;(work/'godot_import.log').write_text(log,encoding='utf-8');print(log)
report=work/'SPLIT_REPORT.md';s=report.read_text(encoding='utf-8');s=s.replace('项目入库检查：未测（需在最终文件落盘后运行）。Godot 无头导入：未测。',f'项目入库检查：实际运行，退出码 {r.returncode}，耗时 {checktime:.3f} 秒；'+('无 FAIL。' if '[FAIL]' not in r.stdout and r.returncode==0 else '有失败，见 inbox_check.log。')+f'\n\nGodot 4.7.2 无头导入：隔离项目实际运行，退出码 {g.returncode}，耗时 {godottime:.3f} 秒；'+('无 ERROR。' if g.returncode==0 and 'ERROR:' not in log else '有错误，见 godot_import.log。')+'\n\n为遵守不修改 assets/scenes/scripts，未运行原项目路径的 --import（会生成 assets 下的 .import 文件）；使用 tools/blender/godot_validation 最小项目导入同一 robot_parts.glb。完整游戏项目导入：未测。')
s+='\n入库命令：`'+ ' '.join(cmd)+'`\n\nGodot 命令：`'+' '.join(cmd2)+'`\n\n导出器有 sampler 选择警告（原材质同一贴图有多个节点）；嵌入三张图片逐字节验证相同。Blender 受限运行中用户配置缓存写入被拒绝，不影响模型输出和检查。\n'
report.write_text(s,encoding='utf-8')
assert r.returncode==0 and '[FAIL]' not in r.stdout,'Inbox failed; see log'
assert g.returncode==0 and 'ERROR:' not in log,'Godot failed; see log'
