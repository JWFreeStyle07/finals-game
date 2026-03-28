# Godot 2D Game - Project Structure

## Folder Layout
```
res://
├── assets/
│   ├── video/
│   │   ├── intro.ogv          ← Your intro cutscene video
│   │   └── play_cutscene.ogv  ← Cutscene before entering level
│   ├── audio/
│   │   ├── menu_music.ogg     ← Background music for main menu
│   │   └── sfx/               ← Any sound effects
│   ├── images/
│   │   └── menu_bg.png        ← Your background image (PNG)
│   └── characters/
│       ├── outfit_1.png       ← Character outfit sprites
│       ├── outfit_2.png
│       └── outfit_3.png       (add more as needed)
├── scenes/
│   ├── intro/
│   │   └── IntroVideo.tscn
│   ├── menus/
│   │   ├── MainMenu.tscn
│   │   ├── LevelsMenu.tscn
│   │   └── SettingsMenu.tscn
│   ├── cutscene/
│   │   └── PlayCutscene.tscn
│   └── levels/
│       ├── Level1.tscn
│       ├── Level2.tscn
│       ├── Level3.tscn
│       ├── Level4.tscn
│       └── Level5.tscn
├── scripts/
│   ├── intro/
│   │   └── intro_video.gd
│   ├── menus/
│   │   ├── main_menu.gd
│   │   ├── levels_menu.gd
│   │   └── settings_menu.gd
│   ├── cutscene/
│   │   └── play_cutscene.gd
│   └── globals/
│       └── GameData.gd        ← AutoLoad singleton
└── project.godot
```

## Setup Steps
1. Create all folders listed above in your Godot project.
2. Add GameData.gd as an AutoLoad singleton (Project > Project Settings > AutoLoad).
3. Place your background PNG at `res://assets/images/menu_bg.png`.
4. Place your intro video at `res://assets/video/intro.ogv` (Godot requires .ogv format).
5. Place menu music at `res://assets/audio/menu_music.ogg`.
6. Set `res://scenes/intro/IntroVideo.tscn` as the Main Scene in Project Settings.

## Video Format Note
Godot 4 only supports `.ogv` (Ogg Theora) video natively via VideoStreamPlayer.
Convert your video using: `ffmpeg -i input.mp4 -c:v libtheora -q:v 7 -c:a libvorbis output.ogv`
