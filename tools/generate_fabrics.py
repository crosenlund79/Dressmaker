#!/usr/bin/env python3
"""Generates the seamless procedural fabric textures in assets/fabrics/.

Channel convention (see shaders/fabric.gdshader):
  R = shading / weave detail (0.8 = neutral)
  G = secondary color mask (0 = primary, 1 = secondary)
  B = additive sheen highlight
  A = coverage (lace holes are transparent)

Usage: python3 tools/generate_fabrics.py   (requires numpy; writes PNGs with the stdlib)
"""
import os
import struct
import zlib

import numpy as np

N = 256
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "fabrics")
rng = np.random.default_rng(1887)
yy, xx = np.mgrid[0:N, 0:N].astype(np.float64)
U = xx / N  # 0..1, periodic
V = yy / N


def periodic_noise(scale, seed=None):
    """Smooth tileable noise via spectral filtering. `scale` ~ feature size in pixels."""
    r = np.random.default_rng(seed) if seed is not None else rng
    white = r.standard_normal((N, N))
    f = np.fft.fftfreq(N)
    fx, fy = np.meshgrid(f, f)
    filt = np.exp(-(fx ** 2 + fy ** 2) * (scale ** 2) * 2.0)
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * filt))
    out -= out.min()
    out /= max(out.max(), 1e-9)
    return out


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def save_png(name, r, g, b, a):
    img = np.stack([r, g, b, a], axis=-1)
    img = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(N))

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(os.path.join(OUT, name + ".png"), "wb") as fh:
        fh.write(png)


def weave(freq, strength):
    """Fine plain-weave texture."""
    warp = 0.5 + 0.5 * np.sin(U * TAU * freq)
    weft = 0.5 + 0.5 * np.sin(V * TAU * freq)
    checker = np.sign(np.sin(U * TAU * freq / 2) * np.sin(V * TAU * freq / 2))
    return (np.where(checker > 0, warp, weft) - 0.5) * strength


TAU = 2 * np.pi
ones = np.ones((N, N))
zeros = np.zeros((N, N))


def cotton():
    r = 0.8 + weave(64, 0.08) + (periodic_noise(3) - 0.5) * 0.08
    save_png("cotton", r, zeros, zeros, ones)


def silk():
    flow = periodic_noise(60, 3)
    sheen = smoothstep(0.35, 1.0, 0.5 + 0.5 * np.sin((V + flow * 0.35) * TAU))
    r = 0.8 + (flow - 0.5) * 0.05 + weave(128, 0.015)
    save_png("silk", r, zeros, sheen * 0.16, ones)


def velvet():
    pile = periodic_noise(2.5, 5)
    crush = periodic_noise(16, 6)
    r = 0.66 + (pile - 0.5) * 0.1 + (crush - 0.5) * 0.14
    sheen = smoothstep(0.7, 0.98, crush) * 0.1
    save_png("velvet", r, zeros, sheen, ones)


def linen():
    slub_u = periodic_noise(1.5, 7)
    slub_v = periodic_noise(1.5, 8)
    lines_u = 0.5 + 0.5 * np.sin(U * TAU * 48 + (slub_u - 0.5) * 3)
    lines_v = 0.5 + 0.5 * np.sin(V * TAU * 48 + (slub_v - 0.5) * 3)
    r = 0.74 + (lines_u * lines_v - 0.25) * 0.25 + (periodic_noise(6, 9) - 0.5) * 0.1
    save_png("linen", r, zeros, zeros, ones)


def satin():
    diag = 0.5 + 0.5 * np.sin((U + V) * TAU * 3 + periodic_noise(30, 10) * 2)
    sheen = smoothstep(0.65, 1.0, diag)
    r = 0.76 + weave(128, 0.03)
    save_png("satin", r, zeros, sheen * 0.45, ones)


def lace():
    # Hexagonal mesh of round holes with floral motifs.
    cells = 8
    cu = U * cells
    cv = V * cells
    gu = (cu % 1.0) - 0.5
    gv = (cv % 1.0) - 0.5
    d = np.sqrt(gu ** 2 + gv ** 2)
    offset_u = ((cu + 0.5) % 1.0) - 0.5
    offset_v = ((cv + 0.5) % 1.0) - 0.5
    d2 = np.sqrt(offset_u ** 2 + offset_v ** 2)
    holes = (smoothstep(0.17, 0.2, d)) * smoothstep(0.08, 0.11, d2)
    ring = np.exp(-((d - 0.3) ** 2) / 0.002)
    alpha = np.clip(holes * 0.95 + ring, 0, 1)
    r = 0.85 + ring * 0.12 - (1 - holes) * 0.1
    save_png("lace", r, ring * 0.0, ring * 0.15, alpha)


def floral():
    cells = 4
    r = 0.8 + weave(64, 0.05)
    mask = zeros.copy()
    for ox, oy in [(0.0, 0.0), (0.5, 0.5)]:
        gu = ((U * cells + ox) % 1.0) - 0.5
        gv = ((V * cells + oy) % 1.0) - 0.5
        ang = np.arctan2(gv, gu)
        rad = np.sqrt(gu ** 2 + gv ** 2)
        petal = 0.22 + 0.1 * np.cos(ang * 5)
        flower = smoothstep(petal + 0.02, petal - 0.02, rad)
        center = smoothstep(0.07, 0.05, rad)
        mask = np.maximum(mask, flower * (1 - center))
        r = r - center * 0.25
    leaves_u = ((U * cells + 0.25) % 1.0) - 0.5
    leaves_v = ((V * cells) % 1.0) - 0.5
    leaf = smoothstep(0.1, 0.06, np.sqrt((leaves_u * 1.8) ** 2 + (leaves_v * 0.9) ** 2))
    r = r - leaf * 0.22
    save_png("floral", r, mask, zeros, ones)


def stripes():
    s = 0.5 + 0.5 * np.sin(U * TAU * 6)
    mask = smoothstep(0.45, 0.55, s)
    thin = smoothstep(0.96, 1.0, 0.5 + 0.5 * np.sin(U * TAU * 6 + np.pi))
    r = 0.8 + weave(96, 0.04) - thin * 0.15
    save_png("stripes", r, mask, zeros, ones)


def check():
    a = smoothstep(0.45, 0.55, 0.5 + 0.5 * np.sin(U * TAU * 8))
    b = smoothstep(0.45, 0.55, 0.5 + 0.5 * np.sin(V * TAU * 8))
    mask = (a + b) * 0.5
    r = 0.8 + weave(96, 0.05)
    save_png("check", r, mask, zeros, ones)


def brocade():
    cells = 2
    gu = ((U * cells) % 1.0) - 0.5
    gv = ((V * cells) % 1.0) - 0.5
    ang = np.arctan2(gv, gu * 0.8)
    rad = np.sqrt((gu * 1.3) ** 2 + gv ** 2)
    medallion = smoothstep(0.3 + 0.06 * np.cos(ang * 6), 0.26 + 0.06 * np.cos(ang * 6), rad)
    inner = smoothstep(0.12, 0.1, rad)
    swirl = np.abs(np.sin(ang * 3 + rad * 20)) * smoothstep(0.42, 0.32, rad) * (1 - medallion)
    corner = smoothstep(0.12, 0.08, np.sqrt((np.abs(gu) - 0.5) ** 2 + (np.abs(gv) - 0.5) ** 2))
    mask = np.clip(medallion * (1 - inner * 0.7) + (swirl > 0.85) * 0.9 + corner, 0, 1)
    r = 0.78 + weave(128, 0.04) + mask * 0.06
    save_png("brocade", r, mask, mask * 0.25, ones)


def polka():
    cells = 6
    gu = ((U * cells) % 1.0) - 0.5
    gv = ((V * cells) % 1.0) - 0.5
    d = np.sqrt(gu ** 2 + gv ** 2)
    gu2 = ((U * cells + 0.5) % 1.0) - 0.5
    gv2 = ((V * cells + 0.5) % 1.0) - 0.5
    d2 = np.sqrt(gu2 ** 2 + gv2 ** 2)
    mask = np.maximum(smoothstep(0.17, 0.14, d), smoothstep(0.17, 0.14, d2))
    r = 0.8 + weave(64, 0.04)
    save_png("polka", r, mask, zeros, ones)


def geometric():
    # Argyle diamonds with a thin overcheck.
    cells = 3
    gu = ((U * cells) % 1.0) - 0.5
    gv = ((V * cells) % 1.0) - 0.5
    diamond = smoothstep(0.02, -0.02, np.abs(gu) + np.abs(gv) - 0.5)
    line1 = np.abs(((U + V) * cells * 2) % 1.0 - 0.5)
    line2 = np.abs(((U - V) * cells * 2) % 1.0 - 0.5)
    thin = smoothstep(0.03, 0.0, np.minimum(line1, line2))
    r = 0.8 + weave(64, 0.04) - thin * 0.25
    save_png("geometric", r, diamond, zeros, ones)


def tartan():
    def bands(t):
        v = np.zeros_like(t)
        for center, width, weight in [(0.1, 0.06, 1.0), (0.35, 0.14, 0.6), (0.62, 0.03, 1.0), (0.8, 0.08, 0.4)]:
            v = np.maximum(v, weight * smoothstep(width, width * 0.7, np.abs(((t - center + 0.5) % 1.0) - 0.5)))
        return v
    a = bands(U * 2 % 1.0)
    b = bands(V * 2 % 1.0)
    twill = 0.5 + 0.5 * np.sign(np.sin((U + V) * TAU * 64))
    mask = np.clip(np.where(twill > 0.5, a, b) * 0.6 + (a * b) * 0.4, 0, 1)
    r = 0.8 + (twill - 0.5) * 0.06 - (a * b) * 0.1
    save_png("tartan", r, mask, zeros, ones)


def houndstooth():
    cells = 16
    cu = U * cells
    cv = V * cells
    iu = np.floor(cu)
    iv = np.floor(cv)
    fu = cu - iu
    fv = cv - iv
    base = ((iu + iv) % 2 == 0)
    tooth = (fu + fv > 1.0) & (fu < 0.5)
    tooth2 = (fu + fv < 1.0) & (fv > 0.5)
    mask = np.where(base, 1.0, 0.0)
    mask = np.where(~base & (tooth | tooth2), 1.0, mask)
    r = 0.8 + weave(128, 0.04)
    save_png("houndstooth", r, mask, zeros, ones)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for fn in [cotton, silk, velvet, linen, satin, lace, floral, stripes, check, brocade, polka, geometric, tartan, houndstooth]:
        fn()
        print("wrote", fn.__name__)
