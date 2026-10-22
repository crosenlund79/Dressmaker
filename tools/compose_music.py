#!/usr/bin/env python3
"""Composes and renders the original soundtrack and sound effects for Sandrines Dresses.

Everything is synthesized from scratch (additive synthesis + convolution reverb), so the
audio is original and free of third-party rights. Requires numpy and ffmpeg (libvorbis).

  python3 tools/compose_music.py            # writes assets/audio/music/*.ogg and assets/audio/sfx/*.ogg

The pieces are generated from hand-written chord progressions and forms with a seeded,
rule-based melody writer (chord tones on strong beats, stepwise motion between, motif
repetition and cadences), in the style of light Victorian parlour and salon music.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 32000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")

MAJOR = [0, 2, 4, 5, 7, 9, 11]


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


# ----------------------------------------------------------------------------- instruments
def env_adsr(n, a, d, s, r, sustain_len):
    """Piecewise envelope (seconds) of total length n samples."""
    t = np.arange(n) / SR
    e = np.ones(n) * s
    e = np.where(t < a, t / max(a, 1e-4), e)
    dec = (t >= a) & (t < a + d)
    e = np.where(dec, 1.0 - (1.0 - s) * (t - a) / max(d, 1e-4), e)
    rel = t >= sustain_len
    e = np.where(rel, s * np.exp(-(t - sustain_len) / max(r, 1e-4) * 4.0), e)
    return e


def piano(freq, dur, vel):
    length = dur + 1.4
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    B = 0.00035
    for k in range(1, 10):
        fk = k * freq * np.sqrt(1 + B * k * k)
        if fk > SR / 2.2:
            break
        amp = (1.0 / k ** 1.25) * (0.6 + 0.4 * vel) ** (k * 0.25)
        decay = 1.1 + k * 0.55 + freq / 900.0
        out += amp * np.sin(2 * np.pi * fk * t + k * 0.7) * np.exp(-t * decay)
    attack = np.minimum(t / 0.004, 1.0)
    release = np.where(t > dur, np.exp(-(t - dur) * 6.0), 1.0)
    hammer = np.random.default_rng(int(freq)).standard_normal(n) * np.exp(-t * 90) * 0.02
    return (out * attack * release + hammer) * vel * 0.32


def strings(freq, dur, vel, bright=1.0):
    length = dur + 0.6
    n = int(length * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.0035 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(t / 0.5, 1.0)
    phase = 2 * np.pi * freq * np.cumsum(vib) / SR
    out = np.zeros(n)
    for k in range(1, 14):
        if k * freq > SR / 2.3:
            break
        out += np.sin(k * phase) / (k ** (1.55 / bright))
    e = env_adsr(n, 0.16, 0.2, 0.85, 0.35, dur)
    return out * e * vel * 0.16


def music_box(freq, dur, vel):
    length = 2.2
    n = int(length * SR)
    t = np.arange(n) / SR
    out = (np.sin(2 * np.pi * freq * t) * np.exp(-t * 2.2)
           + 0.35 * np.sin(2 * np.pi * freq * 3.0 * t) * np.exp(-t * 5.0)
           + 0.15 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * 9.0)
           + 0.08 * np.sin(2 * np.pi * freq * 8.9 * t) * np.exp(-t * 14.0))
    return out * np.minimum(t / 0.002, 1) * vel * 0.26


def harp(freq, dur, vel):
    length = dur + 1.8
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k in range(1, 8):
        if k * freq > SR / 2.3:
            break
        out += np.sin(2 * np.pi * k * freq * t) * np.exp(-t * (1.6 + k * 1.1)) / k ** 1.4
    return out * np.minimum(t / 0.003, 1) * vel * 0.3


def flute(freq, dur, vel):
    length = dur + 0.4
    n = int(length * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 4.8 * t) * np.minimum(t / 0.4, 1)
    phase = 2 * np.pi * freq * np.cumsum(vib) / SR
    out = np.sin(phase) + 0.18 * np.sin(2 * phase) + 0.05 * np.sin(3 * phase)
    breath = np.random.default_rng(int(freq * 7)).standard_normal(n) * 0.02
    e = env_adsr(n, 0.08, 0.1, 0.9, 0.2, dur)
    return (out + breath) * e * vel * 0.18


INSTRUMENTS = {"piano": piano, "strings": strings, "box": music_box, "harp": harp, "flute": flute,
               "cello": lambda f, d, v: strings(f, d, v, bright=0.8)}


# ----------------------------------------------------------------------------- composition
class Piece:
    def __init__(self, key_midi, beats_per_bar, bpm, seed):
        self.key = key_midi
        self.bpb = beats_per_bar
        self.bpm = bpm
        self.rng = np.random.default_rng(seed)
        self.events = []  # (start_beat, dur_beats, midi, vel, instrument)

    def deg_to_midi(self, deg, octave_shift=0):
        o, d = divmod(deg, 7)
        return self.key + MAJOR[d] + 12 * (o + octave_shift)

    def chord_degrees(self, chord):
        root, seventh = chord
        tones = [root, root + 2, root + 4]
        if seventh:
            tones.append(root + 6)
        return tones

    def add(self, start, dur, midi, vel, inst):
        self.events.append((start, dur, midi, vel, inst))

    # --- melody writer
    RHYTHMS = {3: [[2, 1], [1, 1, 1], [1.5, 0.5, 1], [1, 2], [0.5, 0.5, 1, 1], [1, 0.5, 0.5, 1]],
               4: [[2, 2], [1, 1, 2], [1.5, 0.5, 1, 1], [2, 1, 1], [1, 1, 1, 1], [0.5, 0.5, 1, 2]]}
    CADENCE = {3: [[3]], 4: [[4]]}

    def melody_bar(self, chord, prev, rhythm, target=None, final=False):
        tones = [t % 7 for t in self.chord_degrees(chord)]
        notes = []
        pos = 0.0
        p = prev
        for i, dur in enumerate(rhythm):
            strong = pos == 0 or dur >= 1.5 or (self.bpb == 4 and pos == 2)
            if final and i == len(rhythm) - 1:
                cand = [d for d in range(p - 7, p + 8) if d % 7 == 0]
                p = min(cand, key=lambda d: abs(d - p))
            elif strong:
                cand = [d for d in range(p - 5, p + 6) if d % 7 in tones]
                weights = np.array([1.0 / (1 + abs(d - p)) ** 1.3 for d in cand])
                if target is not None:
                    weights *= np.array([1.0 / (1 + 0.3 * abs(d - target)) for d in cand])
                weights /= weights.sum()
                p = int(self.rng.choice(cand, p=weights))
            else:
                step = 1 if (target is not None and target > p) else -1
                if self.rng.random() < 0.3:
                    step = -step
                p += step
            p = int(np.clip(p, 2, 12))
            notes.append((pos, dur, p))
            pos += dur
        return notes, p

    def write_melody(self, chords, start_bar, inst, vel=0.8, octave=1, seed_motif=None):
        """Writes an 8-bar phrase over `chords` (8 entries) with motif repetition. Returns the motif."""
        bpb = self.bpb
        motif = seed_motif
        prev = 7
        if motif is None:
            r1 = self.RHYTHMS[bpb][self.rng.integers(len(self.RHYTHMS[bpb]))]
            r2 = self.RHYTHMS[bpb][self.rng.integers(len(self.RHYTHMS[bpb]))]
            motif = (r1, r2)
        rhythms = [motif[0], motif[1], motif[0], motif[1], motif[0], motif[1],
                   self.RHYTHMS[bpb][self.rng.integers(len(self.RHYTHMS[bpb]))], self.CADENCE[bpb][0]]
        targets = [9, 8, 10, 7, 9, 8, 6, 7]
        for b in range(8):
            final = b == 7
            if b == 3:
                rh = self.CADENCE[bpb][0] if self.rng.random() < 0.5 else [bpb - 1, 1]
            else:
                rh = rhythms[b]
            notes, prev = self.melody_bar(chords[b], prev, rh, targets[b], final)
            arch = 0.85 + 0.15 * np.sin(np.pi * (b + 0.5) / 8)
            for pos, dur, deg in notes:
                self.add((start_bar + b) * bpb + pos, dur * 0.95, self.deg_to_midi(deg, octave), vel * arch, inst)
        return motif

    # --- accompaniment patterns
    def waltz_bass(self, chords, start_bar, inst="piano", vel=0.55):
        for b, ch in enumerate(chords):
            root = self.chord_degrees(ch)[0]
            base = (start_bar + b) * 3
            self.add(base, 1.0, self.deg_to_midi(root % 7, -2), vel, inst)
            for beat in (1, 2):
                for d in self.chord_degrees(ch)[:3]:
                    self.add(base + beat, 0.8, self.deg_to_midi(d % 7, -1), vel * 0.5, inst)

    def arpeggio(self, chords, start_bar, inst="harp", vel=0.45, per_beat=2, octave=-1, span=6):
        for b, ch in enumerate(chords):
            tones = self.chord_degrees(ch)
            pattern = [tones[0], tones[1], tones[2], tones[0] + 7, tones[2], tones[1]]
            steps = self.bpb * per_beat
            for s in range(steps):
                d = pattern[s % min(len(pattern), span)]
                self.add((start_bar + b) * self.bpb + s / per_beat, 1.5 / per_beat, self.deg_to_midi(d % 7 + (7 if d >= 7 else 0), octave), vel * (1.0 if s == 0 else 0.75), inst)

    def pad(self, chords, start_bar, inst="strings", vel=0.5, octave=-1):
        for b, ch in enumerate(chords):
            for i, d in enumerate(self.chord_degrees(ch)[:3]):
                self.add((start_bar + b) * self.bpb, self.bpb * 0.98, self.deg_to_midi(d % 7, octave), vel * (1.0 if i == 0 else 0.8), inst)

    def bass_line(self, chords, start_bar, inst="cello", vel=0.55, beats=None):
        beats = beats or self.bpb
        for b, ch in enumerate(chords):
            root = self.chord_degrees(ch)[0] % 7
            self.add((start_bar + b) * self.bpb, beats * 0.95, self.deg_to_midi(root, -2), vel, inst)

    def alberti(self, chords, start_bar, inst="piano", vel=0.4):
        for b, ch in enumerate(chords):
            t = [d % 7 for d in self.chord_degrees(ch)[:3]]
            order = [t[0], t[2], t[1], t[2]]
            for s in range(self.bpb * 2):
                self.add((start_bar + b) * self.bpb + s * 0.5, 0.5, self.deg_to_midi(order[s % 4], -1), vel, inst)

    # --- render
    def render(self, total_bars, reverb=0.28):
        beat = 60.0 / self.bpm
        total = int(total_bars * self.bpb * beat * SR)
        buf = np.zeros(total)
        for start, dur, midi, vel, inst in self.events:
            sig = INSTRUMENTS[inst](midi_hz(midi), dur * beat, vel)
            s0 = int(start * beat * SR) % total
            end = s0 + len(sig)
            if end <= total:
                buf[s0:end] += sig
            else:
                first = total - s0
                buf[s0:] += sig[:first]
                rest = sig[first:]
                buf[:len(rest)] += rest[:total]  # wrap tails for a seamless loop
        return finish(buf, reverb)


def ch(spec):
    """'I','IV','V7','vi' -> (root degree, seventh)."""
    table = {"I": 0, "ii": 1, "iii": 2, "IV": 3, "V": 4, "vi": 5, "vii": 6}
    seventh = spec.endswith("7")
    return (table[spec.rstrip("7")], seventh)


def prog(s):
    return [ch(x) for x in s.split()]


# ----------------------------------------------------------------------------- mastering
def fft_filter(x, lo=None, hi=None):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    mask = np.ones_like(f)
    if lo:
        mask *= 1 / (1 + (lo / np.maximum(f, 1)) ** 4)
    if hi:
        mask *= 1 / (1 + (f / hi) ** 4)
    return np.fft.irfft(X * mask, len(x))


def reverb_ir(seconds=2.4, seed=5):
    n = int(seconds * SR)
    rng = np.random.default_rng(seed)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-t * 3.2)
    ir = fft_filter(ir, lo=180, hi=5000)
    ir[:int(0.012 * SR)] *= np.linspace(0, 1, int(0.012 * SR))
    return ir / np.sqrt(np.sum(ir ** 2))


def finish(buf, wet):
    # Circular convolution keeps the reverb tail wrapping around the loop point.
    ir = np.zeros(len(buf))
    r = reverb_ir()
    ir[:min(len(r), len(buf))] = r[:len(buf)]
    wet_sig = np.fft.irfft(np.fft.rfft(buf) * np.fft.rfft(ir), len(buf))
    out = buf * (1 - wet) + wet_sig * wet * 2.2
    out = fft_filter(out, lo=35, hi=9000)
    out = np.tanh(out * 1.1) / 1.1
    peak = np.max(np.abs(out)) + 1e-9
    return out * (0.85 / peak)


def write_ogg(path, x, quality=4):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_path = tmp.name
    with wave.open(tmp_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp_path, "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
    os.remove(tmp_path)
    print("wrote", os.path.relpath(path, ROOT), "%.1fs" % (len(x) / SR))


# ----------------------------------------------------------------------------- the pieces
def parlour_waltz():
    p = Piece(key_midi=65, beats_per_bar=3, bpm=138, seed=11)  # F major
    A = prog("I IV V7 I vi ii V7 I")
    B = prog("IV I ii V IV I ii7 V7")
    m = p.write_melody(A, 0, "piano", 0.8)
    p.write_melody(A, 8, "piano", 0.75, seed_motif=m)
    p.write_melody(B, 16, "piano", 0.78)
    p.write_melody(A, 24, "piano", 0.8, seed_motif=m)
    for i, sec in enumerate([A, A, B, A]):
        p.waltz_bass(sec, i * 8)
    p.pad(B, 16, "strings", 0.25, octave=0)
    return p.render(32)


def tea_quartet():
    p = Piece(key_midi=62, beats_per_bar=4, bpm=80, seed=23)  # D major
    A = prog("I vi IV V I iii IV V")
    B = prog("ii V I vi IV V7 I I")
    m = p.write_melody(A, 0, "strings", 0.75, octave=1)
    p.write_melody(B, 8, "strings", 0.72, octave=1)
    p.write_melody(A, 16, "strings", 0.75, octave=1, seed_motif=m)
    p.write_melody(B, 24, "flute", 0.7, octave=1)
    for i, sec in enumerate([A, B, A, B]):
        p.pad(sec, i * 8, "strings", 0.38, octave=0)
        p.bass_line(sec, i * 8, "cello", 0.5, beats=2)
    return p.render(32, reverb=0.32)


def lace_and_lavender():
    p = Piece(key_midi=69, beats_per_bar=3, bpm=92, seed=37)  # A major
    A = prog("I V vi IV I ii V7 I")
    B = prog("vi IV I V vi ii V7 I")
    m = p.write_melody(A, 0, "box", 0.8, octave=1)
    p.write_melody(B, 8, "box", 0.75, octave=1)
    p.write_melody(A, 16, "box", 0.8, octave=1, seed_motif=m)
    for i, sec in enumerate([A, B, A]):
        p.arpeggio(sec, i * 8, "harp", 0.42, per_beat=2, octave=-1)
    return p.render(24, reverb=0.35)


def regent_minuet():
    p = Piece(key_midi=67, beats_per_bar=3, bpm=108, seed=41)  # G major
    A = prog("I V I IV ii V7 I I")
    B = prog("V I vi iii IV I ii7 V7")
    m = p.write_melody(A, 0, "piano", 0.78)
    p.write_melody(A, 8, "piano", 0.74, seed_motif=m)
    p.write_melody(B, 16, "strings", 0.7)
    p.write_melody(A, 24, "piano", 0.8, seed_motif=m)
    for i, sec in enumerate([A, A, B, A]):
        p.alberti(sec, i * 8, "piano", 0.33)
        p.bass_line(sec, i * 8, "cello", 0.3, beats=3)
    return p.render(32)


def gaslight_nocturne():
    p = Piece(key_midi=68, beats_per_bar=4, bpm=64, seed=59)  # A-flat major
    A = prog("I vi ii V I IV V7 I")
    B = prog("IV iii vi ii V iii ii7 V7")
    m = p.write_melody(A, 0, "piano", 0.7, octave=1)
    p.write_melody(B, 8, "piano", 0.65, octave=1)
    p.write_melody(A, 16, "piano", 0.7, octave=1, seed_motif=m)
    for i, sec in enumerate([A, B, A]):
        p.arpeggio(sec, i * 8, "piano", 0.3, per_beat=2, octave=-1)
        p.bass_line(sec, i * 8, "piano", 0.35, beats=4)
    return p.render(24, reverb=0.38)


TRACKS = [
    ("parlour_waltz", "Parlour Waltz in F", "A light-footed piano waltz for the afternoon.", parlour_waltz),
    ("tea_at_half_past_four", "Tea at Half Past Four", "A gentle string quartet with a flute reprise.", tea_quartet),
    ("lace_and_lavender", "Lace & Lavender", "A music-box lullaby over harp arpeggios.", lace_and_lavender),
    ("promenade_on_regent_street", "Promenade on Regent Street", "A courtly minuet for piano and strings.", regent_minuet),
    ("gaslight_nocturne", "Gaslight Nocturne", "A slow, dreamy piano nocturne.", gaslight_nocturne),
]


# ----------------------------------------------------------------------------- sound effects
def noise(n, seed):
    return np.random.default_rng(seed).standard_normal(n)


def sfx_click():
    n = int(0.06 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 2300 * t) * np.exp(-t * 160) * 0.6 + fft_filter(noise(n, 1), lo=1500, hi=6000) * np.exp(-t * 220) * 0.4
    return x / np.max(np.abs(x)) * 0.5


def sfx_rustle():
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    flutter = 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 23 * t + np.sin(2 * np.pi * 7 * t)))
    x = fft_filter(noise(n, 2), lo=1800, hi=7000) * flutter * np.sin(np.pi * t / t[-1]) ** 1.5
    return x / np.max(np.abs(x)) * 0.35


def sfx_radio():
    n = int(0.55 * SR)
    t = np.arange(n) / SR
    click = np.exp(-t * 300) * np.sin(2 * np.pi * 900 * t)
    static = fft_filter(noise(n, 3), lo=800, hi=5000) * np.exp(-((t - 0.25) / 0.12) ** 2) * 0.4
    x = click + static
    return x / np.max(np.abs(x)) * 0.45


def sfx_snip():
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for t0 in (0.02, 0.14):
        m = t >= t0
        tt = t[m] - t0
        x[m] += (np.sin(2 * np.pi * 4200 * tt) + 0.5 * np.sin(2 * np.pi * 6100 * tt)) * np.exp(-tt * 90)
    return x / np.max(np.abs(x)) * 0.4


def clop(n_total, at, seed, gain=1.0, pitch=1.0):
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    c = (np.sin(2 * np.pi * 380 * pitch * t) * 0.6 + fft_filter(noise(n, seed), lo=300, hi=2500) * 0.6) * np.exp(-t * 55)
    out = np.zeros(n_total)
    s = int(at * SR) % n_total
    e = min(n_total, s + n)
    out[s:e] += c[:e - s] * gain
    return out


def sfx_street(seconds=48):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    bed = fft_filter(noise(n, 4), lo=60, hi=500) * 0.25 + fft_filter(noise(n, 5), lo=800, hi=3000) * 0.02
    bed *= 0.8 + 0.2 * np.sin(2 * np.pi * t / seconds * 3)
    x = bed
    rng = np.random.default_rng(6)
    # Distant hooves now and then.
    for start in (6.0, 27.0):
        dur = 7.0
        for k in range(int(dur / 0.36)):
            tt = start + k * 0.36 + (0.08 if k % 2 else 0)
            gain = np.sin(np.pi * (k * 0.36) / dur) * 0.35
            x += clop(n, tt, 100 + k, gain, 1.0 + rng.uniform(-0.05, 0.05))
    # Birds.
    for start in (3.0, 17.5, 38.0):
        m = int(0.12 * SR)
        tt = np.arange(m) / SR
        chirp = np.sin(2 * np.pi * (3200 + 1800 * tt / tt[-1]) * tt) * np.sin(np.pi * tt / tt[-1]) * 0.06
        for r in range(3):
            s = int((start + r * 0.18) * SR)
            x[s:s + m] += chirp
    return x / np.max(np.abs(x)) * 0.5


def sfx_carriage():
    seconds = 7.0
    n = int(seconds * SR)
    t = np.arange(n) / SR
    swell = np.sin(np.pi * t / seconds) ** 1.5
    x = fft_filter(noise(n, 7), lo=40, hi=260) * 0.5 * swell
    for k in range(int(seconds / 0.32)):
        x += clop(n, k * 0.32 + (0.07 if k % 2 else 0), 300 + k, swell[min(n - 1, int(k * 0.32 * SR))] * 0.8)
    return x / np.max(np.abs(x)) * 0.45


def sfx_footsteps():
    seconds = 4.5
    n = int(seconds * SR)
    x = np.zeros(n)
    for k in range(8):
        x += clop(n, 0.3 + k * 0.5, 500 + k, 0.5 + 0.3 * np.sin(np.pi * k / 8), 1.6)
    return fft_filter(x, hi=3000) / (np.max(np.abs(x)) + 1e-9) * 0.35


def sfx_bell():
    n = int(2.0 * SR)
    t = np.arange(n) / SR
    x = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, a, d in [(1320, 1, 2.5), (2700, 0.5, 4), (3960, 0.3, 6), (5280, 0.15, 9)])
    x[int(0.18 * SR):] += (x[:n - int(0.18 * SR)] * 0.6)
    return x / np.max(np.abs(x)) * 0.35


SFX = [("click", sfx_click), ("rustle", sfx_rustle), ("radio_switch", sfx_radio), ("snip", sfx_snip),
       ("street_ambience", sfx_street), ("carriage", sfx_carriage), ("footsteps", sfx_footsteps), ("shop_bell", sfx_bell)]


if __name__ == "__main__":
    os.makedirs(MUSIC_DIR, exist_ok=True)
    os.makedirs(SFX_DIR, exist_ok=True)
    for file_id, _title, _desc, fn in TRACKS:
        write_ogg(os.path.join(MUSIC_DIR, file_id + ".ogg"), fn(), quality=4)
    for file_id, fn in SFX:
        write_ogg(os.path.join(SFX_DIR, file_id + ".ogg"), fn(), quality=3)
