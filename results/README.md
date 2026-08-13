# Results

## Environment

| Item | Value |
|---|---|
| Date | 2026-08-14 (Asia/Shanghai) |
| Host OS | Ubuntu 22.04.5 LTS |
| GPU | NVIDIA GeForce RTX 5090, 32,607 MiB |
| Driver / reported CUDA | 595.71.05 / 13.2 |
| Observed policy-server VRAM | 24,674 MiB |
| JAX | 0.5.3; CUDA device detected |
| PyTorch | 2.7.1+cu126 |
| openpi commit | `15a9616a00943ada6c20a0f158e3adb39df2ccac` |
| Checkpoint | `pi05_libero` |
| Checkpoint bytes | 12,439,085,481 |
| MuJoCo backend | EGL |

## Evaluation

| Suite | Trials/task | Episodes | Successes | Success rate | Videos |
|---|---:|---:|---:|---:|---:|
| `libero_goal` | 1 | 10 | 10 | 100% | 10 |

This is a low-sample end-to-end smoke evaluation, not a statistically stable
replacement for the upstream multi-trial benchmark.

- Machine-readable summary: [`summary.json`](summary.json)
- Per-task record: [`libero_goal-trials1-20260814.txt`](libero_goal-trials1-20260814.txt)

## Verification notes

- JAX detected `CudaDevice(id=0)` and completed a GPU matrix-multiply smoke test.
- LIBERO rendered a `(256, 256, 3)` frame through headless EGL.
- Result parser tests passed: 3/3.
- All six large checkpoint shards were SHA-256 verified; the complete checkpoint
  contained exactly 12,439,085,481 bytes.
- The official client printed an ignored `EGL_NOT_INITIALIZED` destructor warning
  after emitting the final metrics. All 10 episodes and 10 videos were already
  complete, so it does not change the recorded result.
- PyTorch warned that this wheel does not contain `sm_120` kernels. The policy
  inference path uses JAX, which ran on the RTX 5090 successfully.

Raw service/evaluation logs and MP4 files remain on the experiment server and are
excluded from Git because they are generated artifacts.
