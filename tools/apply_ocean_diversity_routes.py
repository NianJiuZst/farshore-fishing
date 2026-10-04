#!/usr/bin/env python3
"""Curate game travel routes without changing a species ID or real distribution.

This is a deliberate game itinerary, not a global biogeographic inventory.
Historic catches retain their original location snapshots and species IDs.
"""
import json
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTES = {
    'atlantic_bluefin_tuna': ['atlantic_ocean'],
    'pacific_bluefin_tuna': ['pacific_ocean'],
    'yellowfin_tuna': ['pacific_ocean', 'indian_ocean'],
    'bigeye_tuna': ['atlantic_ocean'],
    'albacore': ['pacific_ocean'],
    'skipjack_tuna': ['indian_ocean'],
    'mahi_mahi': ['pacific_ocean', 'atlantic_ocean'],
    'wahoo': ['atlantic_ocean', 'indian_ocean'],
    'swordfish': ['atlantic_ocean', 'indian_ocean'],
    'blue_marlin': ['atlantic_ocean'],
    'striped_marlin': ['pacific_ocean'],
    'indo_pacific_sailfish': ['indian_ocean'],
    'great_barracuda': ['atlantic_ocean', 'red_sea'],
    'giant_trevally': ['pacific_ocean', 'indian_ocean', 'red_sea'],
    'greater_amberjack': ['atlantic_ocean'],
    'cobia': ['atlantic_ocean', 'indian_ocean'],
    'roosterfish': ['pacific_ocean'],
    'red_snapper': ['atlantic_ocean'],
    'giant_grouper': ['indian_ocean', 'red_sea'],
    'dogtooth_tuna': ['indian_ocean'],
    'yellowtail_kingfish': ['pacific_ocean'],
    'opah': ['atlantic_ocean'],
    'great_white_shark': ['pacific_ocean', 'atlantic_ocean'],
    'scalloped_hammerhead': ['pacific_ocean'],
    'great_hammerhead': ['atlantic_ocean'],
    'blue_shark': ['pacific_ocean', 'atlantic_ocean'],
    'shortfin_mako': ['pacific_ocean'],
    'tiger_shark': ['indian_ocean'],
    'oceanic_whitetip_shark': ['indian_ocean'],
    'whitetip_reef_shark': ['indian_ocean', 'red_sea'],
}
POINTS = {
    'pacific_ocean': ['pacific_reef', 'pacific_bluewater'],
    'atlantic_ocean': ['atlantic_shelf', 'atlantic_bluewater'],
    'indian_ocean': ['indian_reef', 'indian_bluewater'],
}
RED_POINTS = {
    'great_barracuda': ['red_sea_wall', 'red_sea_bluehole'],
    'giant_trevally': ['red_sea_wall', 'red_sea_bluehole'],
    'giant_grouper': ['red_sea_wall', 'red_sea_bluehole'],
    'whitetip_reef_shark': ['red_sea_wall'],
}
ADDITIONAL_POINTS = {'cobia': ['indian_reef', 'indian_bluewater']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--routes-only', action='store_true', help='Refresh curated species routes without changing the expanded world')
    args = parser.parse_args()
    for part in 'ef':
        path = ROOT / 'game/data' / f'fish_{part}.json'
        values = json.loads(path.read_text())
        for value in values:
            identifier = value['species_id']
            regions = ROUTES[identifier]
            old_spots = value['spot_ids']
            spots = [spot for region in regions if region in POINTS
                     for spot in POINTS[region] if spot in old_spots]
            spots.extend(spot for spot in ADDITIONAL_POINTS.get(identifier, []) if spot not in spots)
            if 'red_sea' in regions:
                spots.extend(RED_POINTS[identifier])
            assert spots, f'Curated species must keep a legal route: {identifier}'
            value['region_ids'] = regions
            value['spot_ids'] = spots
            value['travel_route_note'] = ('1.4.0 游戏旅行路线精选：仅在列出的航段出现，以减少各海域的重复。'
                                          '这里的名单不代表现实独有、绝对缺席或捕捞许可；真实全球分布见自然图鉴。'
                                          '旧物种 ID、历史钓获地点和个人纪录均保留。')
        path.write_text(json.dumps(values, ensure_ascii=False, indent=2) + '\n')
    if args.routes_only:
        return
    path = ROOT / 'game/data/world.json'
    world = json.loads(path.read_text())
    assert not any(r['region_id'] == 'red_sea' for r in world['regions']), 'World already expanded'
    world['regions'].append({
        'region_id': 'red_sea', 'name': '赭岸红海',
        'subtitle': '红海 · 沙漠海岸与珊瑚壁',
        'description': '赭色山岸环绕清透礁湖，蝶鱼、炮弹鱼与长吻海鱼穿过珊瑚壁。这里将红海多处生态环境组合成旅行航段；图鉴保留每种生物的真实分布。',
        'scene': 'res://assets/scenery/red_sea.png', 'color': '#53b9bd',
        'unlock_count': 30, 'unlock_cost': 550,
        'spots': ['red_sea_lagoon', 'red_sea_wall', 'red_sea_bluehole']})
    world['spots'].extend([
        {'spot_id': 'red_sea_lagoon', 'region_id': 'red_sea', 'name': '海葵礁湖',
         'habitat': '1—22米清澈潟湖、海葵、小型珊瑚礁与沙底',
         'depth_min_m': 1, 'depth_max_m': 22, 'min_gear': 0,
         'foreground': 'rocks', 'salinity': 'salt',
         'cast_hint': '轻装近抛找小丑鱼、蝶鱼；贴礁慢收留意鳄形鲬'},
        {'spot_id': 'red_sea_wall', 'region_id': 'red_sea', 'name': '赭岸珊瑚壁',
         'habitat': '10—100米珊瑚壁浅肩、礁台、清水礁坡与外缘巡游区',
         'depth_min_m': 10, 'depth_max_m': 100, 'min_gear': 1,
         'foreground': 'boat', 'salinity': 'salt',
         'cast_hint': '中程沿礁壁探访箱形、圆盘与长吻鱼；一号旅行竿也能覆盖浅肩'},
        {'spot_id': 'red_sea_bluehole', 'region_id': 'red_sea', 'name': '蓝洞外缘',
         'habitat': '30—180米蓝洞外海航段；礁鱼仅在其真实可利用的浅肩水层列入',
         'depth_min_m': 30, 'depth_max_m': 180, 'min_gear': 1,
         'foreground': 'boat', 'salinity': 'salt',
         'cast_hint': '从30米浅肩到深蓝外缘；列表按所持钓竿的实际探深筛选'}])
    for spot in world['spots']:
        if spot['spot_id'] in ('pacific_bluewater', 'atlantic_bluewater', 'indian_bluewater'):
            spot['depth_max_m'] = 700
            spot['habitat'] += '；专用垂降装备可进入700米以内的深水观察航段'
            spot['cast_hint'] += '；深海物种需专用垂降竿，非浅水随机刷出'
    world['gear'].append({
        'id': 5, 'name': '深蓝 · 垂降探海竿', 'price': 540, 'max_depth_m': 700,
        'power': 1.35, 'tolerance': 1.45, 'reach': 0.92,
        'description': '700米虚拟垂降，探访管眼鱼和黑带鱼；战斗强度接近探深竿。游戏自动搭配垂降钓组，不将真实深海调查描绘成岸边浮漂钓法。',
        'rod_length': 2.30, 'rod_radius': 0.017,
        'rod_color': '174f67', 'reel_color': 'a8b9c5', 'grip_color': '283d4b'})
    path.write_text(json.dumps(world, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
