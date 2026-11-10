#!/usr/bin/env python3
"""Write the __label__ of a .p8 cart as a PNG (4x scale). usage: label_png.py cart.p8 out.png"""
import sys, zlib, struct
PAL = ["000000","1d2b53","7e2553","008751","ab5236","5f574f","c2c3c7","fff1e8",
       "ff004d","ffa300","ffec27","00e436","29adff","83769c","ff77a8","ffccaa"]
src = open(sys.argv[1]).read()
rows = src.split('__label__\n')[1].split('\n')[:128]
S = 4
raw = b''
for y in range(128 * S):
    raw += b'\0' + b''.join(bytes.fromhex(PAL[int(rows[y // S][x // S], 32) % 16]) for x in range(128 * S))
ch = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
open(sys.argv[2], 'wb').write(b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', 128*S, 128*S, 8, 2, 0, 0, 0))
                              + ch(b'IDAT', zlib.compress(raw)) + ch(b'IEND', b''))
