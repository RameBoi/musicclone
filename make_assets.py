# Generates the app icon and iPad launch images (no extra packages needed).
import sys, os, zlib, struct

def write_png(path, w, h, row):
    raw = b"".join(b"\x00" + row(y) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    data = (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(data)

def icon_row(size):
    def row(y):
        t = y / float(size)
        r, g, b = int(252 + (250 - 252) * t), int(92 + (36 - 92) * t), int(125 + (60 - 125) * t)
        out = bytearray()
        for x in range(size):
            u, v = x / float(size), y / float(size)
            head = ((u - .37) / .11) ** 2 + ((v - .69) / .09) ** 2 <= 1
            stem = .44 <= u <= .49 and .24 <= v <= .69
            flag = .49 <= u <= .72 and .24 + (u - .49) * .3 <= v <= .36 + (u - .49) * .3
            if head or stem or flag:
                out += b"\xff\xff\xff"
            else:
                out += bytes((r, g, b))
        return bytes(out)
    return row

def solid_row(w):
    line = b"\xff" * (3 * w)
    return lambda y: line

out = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(out, exist_ok=True)
write_png(os.path.join(out, "Icon-76.png"), 76, 76, icon_row(76))
write_png(os.path.join(out, "Icon-76@2x.png"), 152, 152, icon_row(152))
for name, (w, h) in {"Default-Portrait~ipad.png": (768, 1024),
                     "Default-Portrait@2x~ipad.png": (1536, 2048),
                     "Default-Landscape~ipad.png": (1024, 768),
                     "Default-Landscape@2x~ipad.png": (2048, 1536)}.items():
    write_png(os.path.join(out, name), w, h, solid_row(w))
print("assets written to", out)
