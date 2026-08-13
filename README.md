# π0.5-LIBERO Reproduction

这是一个面向单张 NVIDIA GPU 的 **Physical Intelligence π0.5 官方 LIBERO 检查点复现实验**。仓库不复制模型实现或权重，而是固定官方 [`openpi`](https://github.com/Physical-Intelligence/openpi) 版本，并提供服务器预检、安装、评测和结果汇总脚本。

> 当前状态：复现框架已建立；GPU 实测结果将在服务器评测完成后更新。没有实测的数据不会写成已复现结果。

## 实验目标

1. 在单张 RTX 5090 上加载官方 `pi05_libero` 检查点。
2. 跑通图像/语言输入、动作块预测、LIBERO 执行和成功判定的闭环。
3. 记录 GPU、软件版本、显存、运行时间、逐任务结果和轨迹视频。
4. 先做低成本 smoke test，再按需扩大到正式评测。

本实验是 **公开检查点的推理与仿真评测复现**，不包含 π0.5 的预训练或全参数训练。

## 上游版本

- Repository: `Physical-Intelligence/openpi`
- Commit: [`15a9616a00943ada6c20a0f158e3adb39df2ccac`](https://github.com/Physical-Intelligence/openpi/commit/15a9616a00943ada6c20a0f158e3adb39df2ccac)
- Checkpoint: `gs://openpi-assets/checkpoints/pi05_libero`
- Benchmark: LIBERO

官方报告的完整评测结果为 Spatial 98.8、Object 98.2、Goal 98.0、LIBERO-10 92.4，平均 96.85。这里把它作为待验证的参考值，不预先声称本实验能够完全重现。

## 快速开始

推荐 Ubuntu 22.04、NVIDIA Container Toolkit 和 Docker Compose。AutoDL 数据盘建议使用 `/root/autodl-tmp`。

```bash
git clone https://github.com/2021147571/pi0.5test.git
cd pi0.5test
bash scripts/preflight.sh
bash scripts/install.sh
```

先运行一个任务、一个 trial 的低成本测试：

```bash
bash scripts/run_eval.sh libero_goal 1
```

确认闭环正常后，再扩大试验次数：

```bash
bash scripts/run_eval.sh libero_goal 10
```

脚本会打印最终需要执行的官方 Docker Compose 命令，并把日志保存到 `results/raw/`。不同上游版本的 CLI 参数可能变化，因此运行前会校验固定 commit。

## 实验设计

采用分层验证，避免把依赖问题、模型问题和仿真问题混在一起：

```text
GPU / Docker 预检
        ↓
固定 openpi commit 与子模块
        ↓
官方 pi05_libero 权重下载及策略服务
        ↓
LIBERO EGL 离屏渲染与客户端
        ↓
单任务 smoke test
        ↓
多任务、多 trial 正式评测
```

主要指标：

- 成功率：成功 episode 数 / 总 episode 数；
- 逐任务成功率；
- 推理/评测耗时；
- 峰值 GPU 显存；
- 失败轨迹与复现日志。

## 结果

实测后由以下命令生成摘要：

```bash
python scripts/summarize_results.py results/raw/eval.log --output results/summary.json
```

结果模板见 [`results/README.md`](results/README.md)。

## 复现边界

- 使用官方公开的 LIBERO 微调检查点，不从头训练 π0.5。
- smoke test 的单次成功率不等同于论文级统计结论。
- 正式比较需要多个任务、多个 trial，并保留失败轨迹。
- 上游代码和模型权重遵循各自许可证；本仓库只发布原创脚本与实验记录。

## 参考

- [Physical Intelligence/openpi](https://github.com/Physical-Intelligence/openpi)
- [openpi LIBERO guide](https://github.com/Physical-Intelligence/openpi/tree/main/examples/libero)
- [π0.5 project page](https://www.physicalintelligence.company/blog/pi05)

