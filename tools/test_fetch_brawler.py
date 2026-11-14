import urllib.request, io
from PIL import Image

BASE = "https://raw.githubusercontent.com/dylanmpeck/PompaDroid/master/"

# Frame size: 128 x 96
# Crop box in 280x150 source:
# x: 96 to 224 (width 128) -> character center at x=140 is at offset (140-96)=44
# y: 20 to 116 (height 96) -> character feet at y=114-115 is at y=94-95 (near bottom)

hero_poses = {
    "idle": [
        "Assets/Images/Sprites/Hero/hero_idle_00.png",
        "Assets/Images/Sprites/Hero/hero_idle_01.png",
        "Assets/Images/Sprites/Hero/hero_idle_02.png",
        "Assets/Images/Sprites/Hero/hero_idle_03.png",
    ],
    "walk": [
        "Assets/Images/Sprites/Hero/hero_walk_00.png",
        "Assets/Images/Sprites/Hero/hero_walk_01.png",
        "Assets/Images/Sprites/Hero/hero_walk_02.png",
        "Assets/Images/Sprites/Hero/hero_walk_03.png",
        "Assets/Images/Sprites/Hero/hero_walk_04.png",
        "Assets/Images/Sprites/Hero/hero_walk_05.png",
    ],
    "jab": [
        "Assets/Images/Sprites/Hero/hero_attack_00_00.png",
        "Assets/Images/Sprites/Hero/hero_attack_00_01.png",
    ],
    "hook": [
        "Assets/Images/Sprites/Hero/hero_attack_01_00.png",
        "Assets/Images/Sprites/Hero/hero_attack_01_01.png",
    ],
    "upper": [
        "Assets/Images/Sprites/Hero/hero_attack_02_00.png",
        "Assets/Images/Sprites/Hero/hero_attack_02_02.png",
    ]
}

robot_poses = {
    "idle": [
        "Assets/Images/Sprites/Robot/robot_base_idle_00.png",
        "Assets/Images/Sprites/Robot/robot_base_idle_01.png",
        "Assets/Images/Sprites/Robot/robot_base_idle_02.png",
        "Assets/Images/Sprites/Robot/robot_base_idle_03.png",
    ],
    "walk": [
        "Assets/Images/Sprites/Robot/robot_base_walk_00.png",
        "Assets/Images/Sprites/Robot/robot_base_walk_01.png",
        "Assets/Images/Sprites/Robot/robot_base_walk_02.png",
        "Assets/Images/Sprites/Robot/robot_base_walk_03.png",
        "Assets/Images/Sprites/Robot/robot_base_walk_04.png",
        "Assets/Images/Sprites/Robot/robot_base_walk_05.png",
    ],
    "jab": [
        "Assets/Images/Sprites/Robot/robot_base_attack_00.png",
        "Assets/Images/Sprites/Robot/robot_base_attack_01.png",
    ],
    "hook": [
        "Assets/Images/Sprites/Robot/robot_base_attack_02.png",
        "Assets/Images/Sprites/Robot/robot_base_attack_03.png",
    ],
    "upper": [
        "Assets/Images/Sprites/Robot/robot_base_attack_03.png",
        "Assets/Images/Sprites/Robot/robot_base_attack_04.png",
    ]
}

def build_sheet(pose_dict, out_file):
    frames = []
    for k in ["idle", "walk", "jab", "hook", "upper"]:
        for rel in pose_dict[k]:
            url = BASE + rel
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req) as r:
                im = Image.open(io.BytesIO(r.read())).convert("RGBA")
                # crop 128x96
                c = im.crop((96, 20, 224, 116))
                frames.append(c)
    
    total_w = 128 * len(frames)
    sheet = Image.new("RGBA", (total_w, 96), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * 128, 0), f)
    sheet.save(out_file)
    print(f"Saved {out_file}: {sheet.size} with {len(frames)} frames")

build_sheet(hero_poses, "assets/sprites/handcrafted_player_sheet.png")
build_sheet(robot_poses, "assets/sprites/handcrafted_enemy_sheet.png")
