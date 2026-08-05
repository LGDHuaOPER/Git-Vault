---
type: concept
title: 多功能智能体（Generalist Agent）
created: 2026-08-02
updated: 2026-08-02
tags: [AI, 智能体, DeepMind]
related: [gato-加图, deepmind, tong-yi-bian-ma-统一编码, da-xing-ai-yu-yan-mo-xing-大型ai语言模型]
sources: ["得到头条/MD/262.261｜科技前沿 怎样让AI智能更高级？.md"]
---
# 多功能智能体（Generalist Agent）

多功能智能体（Generalist Agent）是指让同一个AI模型具备解决很多不同类型问题能力的智能体。这是[[deepmind]]研究的目标，其2022年5月发表的论文标题即为"A generalist agent"。

## 背景

传统AI模型只专注于完成一类特定任务（如图像识别、语言翻译、辅助决策），每种任务对应特定算法。要让AI同时完成多种任务，只能把几类不同算法都加载到机器人上，相当于给一个机器人配上多个大脑。这样做一是浪费运算资源，二是从技术角度不够优雅。

AI科学家们的长期梦想是开发出像人类一样的智能体，用一个大脑解决多个问题，而不是把一堆算法拼接缝合起来。

## 实现

[[deepmind]]开发的[[gato-加图]]是这一方向的代表成果。Gato利用类似[[da-xing-ai-yu-yan-mo-xing-大型ai语言模型]]的训练原理，通过[[tong-yi-bian-ma-统一编码]]方法，将图像、动作、文字等不同格式信息统一编码为同一种数据序列进行训练，从而用一个算法完成打游戏、聊天、控制机械臂搭积木、给图片配字幕等多种功能。