import json,hashlib
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[2]
fish=json.loads((root/'game/data/fish_b.json').read_text())
logs={a['asset_id']:a for a in json.loads((root/'art_masters/b/generation_log.json').read_text())}
checks={
'atlantic_cod':'三背鳍、双臀鳍、颏须、弯曲浅侧线、斑驳体色已目视确认。',
'pollack':'三背鳍、双臀鳍、弯曲深侧线、前突下颌和黄眼已确认；无长须。',
'saithe':'三背鳍、双臀鳍、接近笔直的浅色侧线、深灰背和叉尾已确认。',
'haddock':'肩部黑拇指斑、黑侧线、尖高第一背鳍和三背双臀鳍已确认；短须可见。',
'atlantic_mackerel':'蓝绿条纹背、无斑银腹、两主背鳍及尾前小鳍列、深叉尾已确认。小鳍为绘画概括，不用它作精确鳍条计数参考。',
'atlantic_herring':'单背鳍、深叉尾、平滑银身与蓝背已确认，无脂鳍或须。',
'european_plaice':'扁平体形、同面两眼、橙红斑、连续长背臀缘和完整尾鳍已确认。外部RGB可含模糊颜色，但实际alpha为0，不是画出的背景。',
'atlantic_wolffish':'宽大头、显露犬齿、长连续背臀鳍、深竖带与圆尾已确认；无腹鳍。',
'european_seabass':'双背鳍、较大口、成鱼无斑银体、灰背与叉尾已确认。',
'gilthead_seabream':'金色额带、鳃盖黑斑及下缘红色、深椭圆体与单连续背鳍已确认。',
'saddled_seabream':'白边黑尾鞍、银体细纵线、偏上翘小口和单连续背鳍已确认。',
'white_seabream':'尾柄上黑鞍未包住底部、深色鳃盖边、深腹鳍与浅前缘已确认。',
'annular_seabream':'近闭合尾黑环、黄腹鳍及臀鳍前部、无竖纹银身已确认。',
'red_mullet':'双颏须、陡额、两分离背鳍、无纹第一背鳍、无粗黄侧条已确认。',
'painted_comber':'头部红蓝曲线、腹部蓝斑、深竖带、黄尾、单连续背鳍已确认。',
'common_pandora':'粉银体、上半身细蓝点、较长吻、红鳃盖上缘、单背鳍与叉尾已确认。'
}
assets=[]
for f in fish:
 id=f['species_id'];master=root/f'art_masters/b/{id}.png';main=root/f'game/assets/fish/{id}.png';thumb=root/f'game/assets/fish/{id}_thumb.png'
 im=Image.open(master);rt=Image.open(main);th=Image.open(thumb)
 assert im.mode=='RGBA' and rt.mode=='RGBA' and th.mode=='RGBA'
 assert rt.width<=1024 and th.width<=256 and im.getchannel('A').getextrema()[0]==0
 h=im.getchannel('A').histogram();transparent=h[0]/(im.width*im.height)
 assert transparent>.25
 a={'asset_id':id,'purpose':'鱼类图鉴详情、钓获展示及列表缩略图','master_path':str(master.relative_to(root)),'runtime_path':str(main.relative_to(root)),'thumbnail_path':str(thumb.relative_to(root)),'master_dimensions':list(im.size),'runtime_dimensions':list(rt.size),'thumbnail_dimensions':list(th.size),'alpha_mode':im.mode,'alpha_range':list(im.getchannel('A').getextrema()),'fully_transparent_fraction':round(transparent,5),'source':'OpenAI built-in image_gen; one independent generation call per species','generation_date':'2026-10-02','prompt':logs[id]['prompt'],'reference_image_inputs':[],'research_sources':f['sources'],'license_status':'项目独立AI生成素材；未复制网页照片或第三方插画。工具使用条款适用，未声称生成自动解决全部商业权利问题。来源网页文本与照片仍归各权利人，未获照片复用授权。','review_status':'完成制作级形态与透明通道审核；非科研鉴定图版','anatomy_review':checks[id],'orientation':'head left, full fish','alpha_review':'真RGBA，图外有完整透明像素；未使用程序抠图或替换绘画；仅等比Lanczos缩放','runtime_sha256':hashlib.sha256(main.read_bytes()).hexdigest(),'used_by':[f['art'],f['thumb']]}
 assets.append(a)
manifest={'schema_version':1,'group':'B: Norway and Mediterranean fish','count':len(assets),'verification_note':'所有16幅分别生成、目視審核并核对实际保存路径；无占位图片。主绘图保留在game之外，运行纹理最长宽边1024，列表图256。','assets':assets}
(root/'docs/ASSETS_B.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
# QA contact sheets use actual art unchanged, composited for review only.
for style,bg in [('light',(242,235,216,255)),('dark',(20,46,57,255))]:
 sheet=Image.new('RGBA',(1280,1280),bg);dr=ImageDraw.Draw(sheet)
 for n,f in enumerate(fish):
  x=(n%4)*320;y=(n//4)*320
  im=Image.open(root/f"game/assets/fish/{f['species_id']}.png");im.thumbnail((302,240),Image.Resampling.LANCZOS)
  sheet.alpha_composite(im,(x+(320-im.width)//2,y+32+(240-im.height)//2))
  dr.text((x+9,y+286),f['species_id'],fill=(20,30,30,255) if style=='light' else (240,240,225,255))
 sheet.convert('RGB').save(root/f'art_masters/b/contact_{style}.jpg',quality=92)
print('PASS: 16 assets RGBA, widths <=1024/256, alpha backgrounds, preserved masters')
print('Master total MB',round(sum((root/a['master_path']).stat().st_size for a in assets)/1048576,2))
print('Runtime + thumbs MB',round(sum((root/a[k]).stat().st_size for a in assets for k in ['runtime_path','thumbnail_path'])/1048576,2))
print([(a['asset_id'],a['runtime_dimensions'],a['fully_transparent_fraction']) for a in assets])
