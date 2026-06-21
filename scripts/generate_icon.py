#!/usr/bin/env python3
"""Generate app icon for Setoran Mobil"""
from PIL import Image, ImageDraw
import os

os.makedirs('assets/icon', exist_ok=True)

W, H = 1024, 1024
NAVY  = (21, 101, 192)
GOLD  = (255, 179, 0)
WHITE = (255, 255, 255)
DARK  = (0, 30, 80)

# ── FULL ICON ──────────────────────────────────────
img  = Image.new('RGBA', (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background circle
draw.ellipse([0, 0, W, H], fill=NAVY)

# Gold ring
draw.ellipse([30, 30, W-30, H-30],
             outline=GOLD, width=40)

# Car body
draw.rounded_rectangle(
    [160, 460, 864, 680],
    radius=50, fill=WHITE)

# Car roof
draw.rounded_rectangle(
    [260, 300, 764, 480],
    radius=40, fill=WHITE)

# Windows
draw.rounded_rectangle(
    [290, 320, 500, 460],
    radius=20, fill=NAVY)
draw.rounded_rectangle(
    [524, 320, 734, 460],
    radius=20, fill=NAVY)

# Wheels
draw.ellipse([190, 630, 360, 800],
             fill=DARK, outline=GOLD, width=20)
draw.ellipse([664, 630, 834, 800],
             fill=DARK, outline=GOLD, width=20)

# Wheel center
draw.ellipse([255, 695, 295, 735],
             fill=GOLD)
draw.ellipse([729, 695, 769, 735],
             fill=GOLD)

# Headlight
draw.rounded_rectangle(
    [820, 510, 870, 560],
    radius=10, fill=GOLD)

# Taillight
draw.rounded_rectangle(
    [154, 510, 204, 560],
    radius=10, fill=(255, 80, 80))

img.save('assets/icon/app_icon.png')
print("✅ app_icon.png created")

# ── FOREGROUND (adaptive icon) ──────────────────────
fg   = Image.new('RGBA', (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(fg)

# Car body
draw.rounded_rectangle(
    [160, 460, 864, 680],
    radius=50, fill=WHITE)

# Car roof
draw.rounded_rectangle(
    [260, 300, 764, 480],
    radius=40, fill=WHITE)

# Windows
draw.rounded_rectangle(
    [290, 320, 500, 460],
    radius=20, fill=NAVY)
draw.rounded_rectangle(
    [524, 320, 734, 460],
    radius=20, fill=NAVY)

# Wheels
draw.ellipse([190, 630, 360, 800],
             fill=DARK, outline=GOLD, width=20)
draw.ellipse([664, 630, 834, 800],
             fill=DARK, outline=GOLD, width=20)

# Wheel center
draw.ellipse([255, 695, 295, 735], fill=GOLD)
draw.ellipse([729, 695, 769, 735], fill=GOLD)

# Headlight
draw.rounded_rectangle(
    [820, 510, 870, 560],
    radius=10, fill=GOLD)

# Taillight
draw.rounded_rectangle(
    [154, 510, 204, 560],
    radius=10, fill=(255, 80, 80))

fg.save('assets/icon/app_icon_fg.png')
print("✅ app_icon_fg.png created")
