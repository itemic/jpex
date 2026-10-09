"""Joins screenshots side by side: sheet.py out.png a.png b.png ..."""
import sys
from PIL import Image
ims = [Image.open(f) for f in sys.argv[2:]]
s = 0.45
w, h = int(ims[0].size[0] * s), int(ims[0].size[1] * s)
out = Image.new('RGB', (w * len(ims), h))
for i, im in enumerate(ims):
    out.paste(im.resize((w, h)), (i * w, 0))
out.save(sys.argv[1])
