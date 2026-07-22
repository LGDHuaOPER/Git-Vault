---
title: What Is LLM Observability & Monitoring?
source: https://www.datadoghq.com/knowledge-center/llm-observability/
author:
  - "[[Datadog]]"
published: 2024-04-23
created: 2026-07-22
description: Discover how LLM observability provides visibility into LLM application performance, and how to use it to improve reliability, cost, and output quality.
tags:
  - Clippings
  - AI可观测
  - AI可观测/LLM-Observability
---
## What is LLM Observability?

**LLM observability** is a set of tools, techniques, and practices that give engineering and data science teams continuous visibility into the behavior and performance of large language model (LLM) applications. It covers monitoring inputs and outputs, tracing requests through model chains, tracking latency and token usage, and detecting issues like hallucinations, cost overruns, and security vulnerabilities—before they affect users.

Running LLM applications in production is fundamentally different from traditional software. Outputs are non-deterministic, model chains are opaque, and failures don’t always surface as errors—they surface as wrong or low-quality responses. LLM observability provides the instrumentation needed to manage that complexity at scale.

## What are the common issues with LLM applications?

LLM applications in production are exposed to a distinct set of failure modes that traditional monitoring tools aren’t built to catch. Common issues include:

1. **Hallucinations**: LLM powered applications may occasionally produce false information, a phenomenon referred to as “hallucinating”, particularly when confronted with queries for which they do not possess an answer. Rather than acknowledging their lack of knowledge, they frequently yield responses that may appear assured but are essentially flawed. This propensity can potentially foster the spread of inaccurate information, a consideration that is crucial when applying LLMs to activities that necessitate factual accuracy.
2. **Performance and cost**: Often the applications built using LLMs rely on third-party models. This dependence can lead to issues such as performance degradation of third-party APIs, inconsistencies due to changes in their algorithms, and high costs—especially with large data volumes.
3. **Prompt hacking**: Prompt hacking, or sometimes referred to as prompt injection, is a technique where users can influence LLM applications to produce specific content. This manipulation can potentially cause LLMs to generate inappropriate or harmful material. Awareness of this issue is vital, particularly when deploying LLMs in customer-facing applications.
4. **Security and data privacy**: LLMs pose security issues, including potential data leaks, output biases due to skewed training data, and risks of unauthorized access. Additionally, LLMs may generate a response containing sensitive or personal data. Thus, stringent security measures and ethical practices are vital with LLMs.
5. **Model prompt and response variance**: The user prompts received by LLMs and the responses they generate vary in attributes such as length, language, and accuracy. Users may also receive different responses to the same query, which may lead to confusion and inconsistent user experience. This enforces the need for continuous monitoring and logging of LLM applications.

## What are the benefits of LLM observability?

Organizations that instrument their LLM applications gain several concrete advantages:

1. **Improved LLM application performance**: LLM observability enables real-time monitoring of various performance evaluation metrics such as latency and throughput of LLM applications and quality of responses. By continuously monitoring these metrics, data scientists and engineers can quickly identify any deviations or degradation in LLM performance. This proactive approach allows for timely intervention, leading to improved model performance and user experience.
2. **Better explainability**: With LLM observability, you can get deep model insights into the inner workings of LLM applications. By visualizing the request-response pairs, word embeddings, or prompt chain sequence, LLM observability enhances the interpretability of responses. This increased transparency enables stakeholders to trust LLM applications’ decisions and identify any quality issue or errors in the application’s outputs and logic.
3. **Faster issue diagnosis**: End-to-end visibility into the operation of an LLM application is essential to resolve issues such as no or incorrect responses. LLM observability enables engineers to analyze the backend operations and API calls for a request to pinpoint the root cause of an issue, reducing the time it takes to resolve the issue.
4. **Increased security**: LLM observability plays a crucial role in enhancing the security of LLM applications by monitoring model behaviors for potential security vulnerabilities or malicious attacks. By tracking access patterns, input data, and model outputs, LLM observability tools can detect anomalies that may indicate data leaks or adversarial attacks. This continuous monitoring helps data scientists and security teams proactively identify and mitigate security threats, safeguarding sensitive data and maintaining the integrity of LLM applications.
5. **Efficient cost management**: Observing the resource consumption and utilization of LLM models allows organizations to optimize resource allocation and cost based on actual usage patterns. By monitoring metrics such as token consumption, CPU/GPU utilization, and memory usage, observability tools help in identifying resource bottlenecks or underutilization. These insights can inform decisions on scaling resources up or down, ensuring cost-effectiveness of LLM applications.

## What should you look for in an LLM observability solution?

When considering a solution that supports AI observability for generative AI and language models, review these features offered by LLM monitoring tools:

1. **LLM chain debugging**: A majority of modern LLM applications are built by logically chaining LLM agents together where output from one is fed as input to another before returning the final output to the user. This can make it hard to understand why an LLM agent is looping or why a chain is slower than expected. Hence it is essential that the LLM monitoring tool provides the visibility into the complete operation of LLM chains for swift troubleshooting and issue resolution.
2. **Visibility into complete application stack**: The symptoms of the issues happening in the backend of LLM applications appear at the user interface of the application. For efficient troubleshooting, it is essential to know which element of the LLM application stack (GPU, database, service, or model) failed upfront.The scope of your LLM observability solution should cover the entire application stack and areas relevant to your needs.
3. **Explainability and anomaly detection**: An ideal LLM observability solution should provide insights into the decision-making process of AI models, promoting transparency and explainability. Additionally, the solution should have out-of-the-box capability to effectively monitor and analyze data inputs and outputs to detect anomalies, biases, and user feedback.
4. **Scalability, integration, and security**: LLM monitoring solutions should be highly scalable to handle increasing user workloads while seamlessly integrating with various LLM platforms used by applications. It must provide robust security features including PII redaction, sensitive data scanning, and protection against prompt hacking.
5. **Full lifecycle support**: While LLM observability is essential for smooth LLM operations in production, it also plays a key role in experimenting and fine-tuning of models during development phases.

## Learn more about Datadog Agent Observability

[Datadog Agent Observability](https://www.datadoghq.com/product/llm-observability/) provides end-to-end visibility for LLM applications—tracking inputs, outputs, token usage, and latency across every step of a model chain. It supports a wide range of providers, including OpenAI, Amazon Bedrock, and others, with built-in evaluations for hallucination detection, prompt injection, and output quality.

To get started, see the [Agent Observability documentation](https://docs.datadoghq.com/llm_observability/) or explore [Datadog’s AI integrations](https://www.datadoghq.com/blog/ai-integrations/).