# Analysis: 2D Particles Demo → Behind Mask Integration

## What the 2d/particles project offers

The **2d/particles** demo showcases high-quality 2D particle systems in Godot:

- **GPUParticles2D** (GPU-accelerated) with **ParticleProcessMaterial**
- **Textures**: `fire_particle.png`, `smoke_particle.png`, `spark_particle2.png`, `flipbook.png` — soft, gradient-friendly sprites
- **Color ramps**: `GradientTexture1D` for fade-in/out and tint over lifetime (e.g. orange→yellow→transparent for fire)
- **Scale curves**: `CurveTexture` so particles grow or shrink over lifetime
- **Additive blending**: `CanvasItemMaterial` with `blend_mode = 1` for glow
- **Emission shapes**: sphere, box, ring, points; radial/linear acceleration
- **Effects**: Fire, Smoke, Magic (ring), Explosion, Flipbook animation, Subemitters, Turbulence, Collision

## Current behind_mask particles

- **CPUParticles2D** only, created in code in `ParticleManager.gd`
- No textures — solid-color quads
- No gradients or scale curves
- Used for: hit sparks, explosions, dust

## How we can apply the demo

1. **Reuse textures**  
   Copy `spark_particle2.png`, `smoke_particle.png` (and optionally `fire_particle.png`) into `2d/behind_mask/art/particles/` so we can reference them from behind_mask.

2. **Pre-made particle scenes**  
   Add three scenes:
   - **HitSparksParticles.tscn** — GPUParticles2D + spark texture + short lifetime, additive blend, small sphere emission
   - **ExplosionParticles.tscn** — GPUParticles2D + smoke/spark texture + color ramp (orange→transparent), radial accel, scale curve
   - **DustParticles.tscn** — GPUParticles2D + smoke texture + soft color ramp, low gravity, slow drift

3. **ParticleManager**
   - Preload these scenes and spawn them at the requested position (and optional scale/color).
   - When a scene is missing, keep falling back to the current CPUParticles2D-in-code behavior so the game still runs.

4. **Optional polish**
   - Use the same additive `CanvasItemMaterial` on GPU particles for a glow look.
   - Tweak emission radius, amount, and lifetime to match game feel (e.g. explosions a bit bigger/brighter for boss/death).

This keeps behind_mask independent (no runtime dependency on 2d/particles) while making hit sparks, explosions, and dust visually closer to the particles demo.
