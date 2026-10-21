#!/usr/bin/env python3
"""
Membuat efek suara Bebaca (WAV mono 44.1 kHz) -> assets/sounds/
Jalankan ulang bila ingin mengubah nada:   pip install numpy && python3 tool/generate_sounds.py
Mau pakai suara sendiri? Ganti file di assets/sounds/ dengan nama yang sama (.wav).
"""
import os
import wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'sounds')
os.makedirs(OUT, exist_ok=True)

# frekuensi nada (Hz)
N = dict(G4=392.00, C5=523.25, D5=587.33, E5=659.25, G5=783.99, A5=880.00, B5=987.77,
         C6=1046.50, D6=1174.66, E6=1318.51, G6=1567.98, A6=1760.00, C7=2093.00)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def bell(freq, dur, tau=0.18, attack=0.004, partials=((1, 1.0), (2, 0.30), (3, 0.10))):
    """Nada lonceng lembut: beberapa harmonik, meluruh eksponensial."""
    t = t_axis(dur)
    wave_ = sum(a * np.sin(2 * np.pi * freq * k * t) for k, a in partials)
    env = np.exp(-t / tau) * np.minimum(1.0, t / attack)
    return wave_ * env


def sweep(f0, f1, dur, tau=None, attack=0.01):
    t = t_axis(dur)
    f = f0 + (f1 - f0) * (t / dur)
    phase = 2 * np.pi * np.cumsum(f) / SR
    env = np.minimum(1.0, t / attack) * (np.exp(-t / tau) if tau else np.sin(np.pi * t / dur))
    return np.sin(phase) * env


def knock(freq=520, dur=0.15):
    """Ketukan kayu: nada pendek + sedikit 'klik'."""
    t = t_axis(dur)
    body = np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.028)
    body += 0.4 * np.sin(2 * np.pi * freq * 2.4 * t) * np.exp(-t / 0.012)
    rng = np.random.default_rng(7)
    click = rng.standard_normal(len(t)) * np.exp(-t / 0.004) * 0.25
    return body + click


def mix(events, total):
    out = np.zeros(int(SR * total))
    for offset, sig, gain in events:
        i = int(SR * offset)
        seg = sig[: max(0, len(out) - i)]
        out[i:i + len(seg)] += seg * gain
    return out


def save(name, sig, peak=0.8):
    sig = sig / (np.max(np.abs(sig)) or 1) * peak
    fade = int(SR * 0.015)                       # fade-out singkat agar tidak 'klik'
    sig[-fade:] *= np.linspace(1, 0, fade)
    pcm = (sig * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# ---- efek ----
save('tap', knock())

save('correct', mix([(0.00, bell(N['E5'], 0.5), 1.0),
                     (0.09, bell(N['A5'], 0.5), 1.0)], 0.6))

save('wrong', mix([(0.00, sweep(330, 262, 0.15), 1.0),
                   (0.13, sweep(277, 196, 0.22), 1.0)], 0.4), peak=0.6)

save('next', sweep(420, 980, 0.13) + 0.3 * knock(700, 0.13), peak=0.55)

save('success', mix([(0.00, bell(N['C5'], 0.9, 0.25), 0.9),
                     (0.09, bell(N['E5'], 0.9, 0.25), 0.9),
                     (0.18, bell(N['G5'], 0.9, 0.25), 0.9),
                     (0.27, bell(N['C6'], 1.0, 0.35), 1.1)], 1.3))

for i, f in enumerate(('C6', 'E6', 'G6'), start=1):      # satu nada per bintang
    save(f'star{i}', bell(N[f], 0.55, 0.16, partials=((1, 1.0), (2, 0.5), (3.01, 0.25))), peak=0.7)

save('fanfare', mix([(0.00, bell(N['G4'], 0.5, 0.2), 0.8),
                     (0.14, bell(N['C5'], 0.5, 0.2), 0.8),
                     (0.28, bell(N['E5'], 0.5, 0.2), 0.8),
                     (0.46, bell(N['C5'], 1.6, 0.55), 0.7),
                     (0.46, bell(N['E5'], 1.6, 0.55), 0.7),
                     (0.46, bell(N['G5'], 1.6, 0.55), 0.7),
                     (0.46, bell(N['C6'], 1.6, 0.6), 0.9)], 2.2))

save('mic_on', mix([(0.00, bell(N['E5'], 0.12, 0.05), 1.0),
                    (0.08, bell(N['B5'], 0.16, 0.06), 1.0)], 0.26), peak=0.6)

# nada pembuka splash: tangga nada pentatonik naik, berkilau
notes = ['C6', 'D6', 'E6', 'G6', 'A6', 'C7']
save('chime', mix([(0.11 * i, bell(N[n], 1.3, 0.42, partials=((1, 1.0), (2, 0.4), (3.01, 0.2))), 0.8 + 0.05 * i)
                   for i, n in enumerate(notes)], 1.9), peak=0.6)

print('selesai ->', os.path.abspath(OUT))
