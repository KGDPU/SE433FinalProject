# SE433 Final Project: Improving Regression Test Generation with mini-SWE-agent

## Project Overview

This project investigates whether providing an LLM-based software testing agent with instructions and examples of common software defect patterns improves its ability to generate effective regression tests.

The experiment uses mini-SWE-agent with the DeepSeek-Flash language model and evaluates generated regression tests using SWT-Bench.

The experiment compares two configurations across the same 25 selected SWE-bench Lite instances:

- **Baseline:** mini-SWE-agent using the original prompt configuration.
- **Enhanced:** The same agent and language model, with additional instructions concerning common software defect patterns and guidance for generating regression tests that exercise potentially overlooked behaviors.

The experimental treatment modifies the prompt context rather than the underlying agent execution workflow.

## Research Question

Does providing an LLM with instructions and examples of common software development defect patterns improve generated test coverage compared with an unchanged DeepSeek baseline under the same experimental conditions?

## Experimental Design

Two configurations were evaluated:

- **Baseline:** The original mini-SWE-agent prompt configuration.
- **Enhanced:** The baseline configuration with additional defect-pattern instructions covering common sources of software defects, including boundary conditions, unexpected inputs, state mutation, nested objects, ordering, and silent incorrect behavior.

Both configurations used:

- DeepSeek-Flash through LiteLLM (`deepseek/deepseek-flash`).
- The same 25 SWT-Bench instances.
- The SWE-bench Lite test split.
- One generation worker.
- The same SWT-Bench evaluation procedure.
- One evaluation worker.

The 25 instances were selected randomly from 276 eligible SWE-bench Lite test instances using random seed 443.

The agent was tasked with generating regression tests that reproduce reported defects, rather than modifying application code to fix them.

## Results Summary

| Metric | Baseline | Enhanced |
|---|---:|---:|
| Assigned instances | 25 | 25 |
| Instances evaluated | 21 | 21 |
| Successfully reproduced | 20 | 18 |
| Reproduction success rate (25 assigned) | 80.00% | 72.00% |
| Mean coverage | 80.92% | 86.03% |
| Mean coverage delta | 0.5146 | 0.6446 |
| LLM inference cost | $0.24 | $0.24 |
| LLM API calls | Not yet established | Not yet established |
| Generation wall-clock time | 43m 34s | 45m 20s |

The enhanced configuration increased mean code coverage by approximately 5.11 percentage points and mean coverage delta by approximately 0.1300.

However, issue reproduction success decreased from 80.00% to 72.00%. The enhanced configuration also required approximately 4.1% more generation time, while recorded LLM inference costs remained identical.

The reproduction outcomes differed between configurations:

- Eighteen instances were successfully reproduced by both configurations.
- One evaluated instance remained unresolved in both configurations: `sympy__sympy-15308`.
- Two instances were resolved only by the baseline: `django__django-13933` and `sympy__sympy-16281`.
- No instances were resolved only by the enhanced configuration.
- Four instances experienced generation failures in both configurations and could not be evaluated.

These findings indicate that the additional defect-pattern instructions increased measured code coverage but did not improve overall issue reproduction success.

## Repository Structure

The research artifacts are organized under `research_artifacts/`.

```text
SE433FinalProject/
├── mini-swe-agent/
│   └── ...                         # Agent source and configuration
├── swt-bench/
│   └── ...                         # Benchmark source and evaluation tools
├── research_artifacts/
│   ├── configs/
│   │   └── pilot25_ids.txt
│   ├── generation/
│   │   ├── baseline25/
│   │   └── enhanced25/
│   ├── predictions/
│   │   ├── baseline25.swtbench.jsonl
│   │   ├── enhanced25.swtbench.jsonl
│   │   ├── baseline25.submitted_ids.txt
│   │   └── enhanced25.submitted_ids.txt
│   ├── evaluation/
│   │   ├── deepseek__deepseek-flash.baseline25.json
│   │   └── deepseek__deepseek-flash.enhanced25.json
│   ├── instance_logs/
│   │   ├── baseline25/
│   │   └── enhanced25/
│   ├── analysis/
│   │   ├── create_comparison.py
│   │   ├── results_comparison.csv
│   │   └── instance_outcomes.csv
│   └── case_studies/
│       ├── django__django-13933/
│       ├── sympy__sympy-16281/
│       ├── sympy__sympy-15308/
│       ├── django__django-10924/
│       ├── django__django-13028/
│       └── django__django-13447/
└── README.md
```

The directory tree highlights the principal research artifacts and is not an exhaustive listing. The original mini-SWE-agent and SWT-Bench source directories should retain their respective project files.

## Reproducing the Experiment

The experiment consists of two primary stages:

1. Generate regression test patches using mini-SWE-agent and DeepSeek-Flash.
2. Evaluate the generated patches using SWT-Bench.

Commands below assume a Linux or WSL environment. Relative paths should be adjusted if the repository is organized differently.

### Prerequisites

The experiment requires:

- Python and the dependencies required by mini-SWE-agent and SWT-Bench.
- A configured Python environment.
- Docker Desktop with WSL2 integration or a compatible Docker environment.
- Access to DeepSeek-Flash through LiteLLM.
- Appropriate model API credentials.

API credentials must be configured locally and must not be committed to the repository.

Install each project's dependencies according to its included setup instructions.

### Step 1: Select the SWT-Bench Instances

The experiment uses 25 instances selected from the SWE-bench Lite test split.

The selected instance identifiers are preserved in the experiment configuration artifacts.

The same instance selection must be used for both baseline and enhanced configurations to maintain a controlled comparison.

The random selection used seed 443.

### Step 2: Generate Baseline Regression Tests

Run mini-SWE-agent using the baseline prompt configuration and the selected 25 instances.

The generation outputs are preserved under:

`research_artifacts/generation/baseline25/`

The resulting predictions are stored in:

`research_artifacts/predictions/baseline25.swtbench.jsonl`

### Step 3: Generate Enhanced Regression Tests

Run mini-SWE-agent using the enhanced prompt configuration.

The enhanced configuration includes additional defect-pattern instructions while keeping the model and agent execution workflow unchanged.

The generation outputs are preserved under:

`research_artifacts/generation/enhanced25/`

The resulting predictions are stored in:

`research_artifacts/predictions/enhanced25.swtbench.jsonl`

### Step 4: Evaluate Baseline Predictions

From the SWT-Bench project directory, execute:

```bash
uv run python -m src.main \
  --dataset_name princeton-nlp/SWE-bench_Lite \
  --predictions_path research_artifacts/predictions/baseline25.swtbench.jsonl \
  --max_workers 1 \
  --run_id baseline25
```

Adjust the prediction path to the correct relative path from the SWT-Bench working directory.

The aggregate evaluation result is preserved as:

`research_artifacts/evaluation/deepseek__deepseek-flash.baseline25.json`

### Step 5: Evaluate Enhanced Predictions

Using the same evaluation environment and worker count, execute:

```bash
uv run python -m src.main \
  --dataset_name princeton-nlp/SWE-bench_Lite \
  --predictions_path research_artifacts/predictions/enhanced25.swtbench.jsonl \
  --max_workers 1 \
  --run_id enhanced25
```

The aggregate evaluation result is preserved as:

`research_artifacts/evaluation/deepseek__deepseek-flash.enhanced25.json`

Both configurations use the same benchmark dataset and evaluation procedure. Only the prediction file and run identifier differ.

### Step 6: Generate the Comparison Results

From the SWT-Bench project directory, execute:

```bash
python3 research_artifacts/analysis/create_comparison.py
```

This produces:

- `research_artifacts/analysis/results_comparison.csv`
- `research_artifacts/analysis/instance_outcomes.csv`

These files provide the per-instance comparison and aggregate results used in the analysis.

## Evaluation Metrics

The following measurements were used to compare the two configurations.

### Issue Reproduction Success Rate

The percentage of assigned instances successfully classified as resolved by SWT-Bench.

The denominator includes all 25 assigned instances. Instances that failed during generation are counted as unsuccessful for this overall rate, but are distinguished from evaluated unresolved instances.

### Code Coverage

Mean code coverage and mean coverage delta were obtained from SWT-Bench evaluation results.

Mean coverage measures the average reported coverage across instances with available coverage measurements.

Mean coverage delta represents the average proportion of executable lines covered by the generated tests relative to the evaluator's coverage-delta calculation.

### Computational Cost

Recorded LLM inference costs were compared between configurations.

Both configurations incurred $0.24 in recorded inference costs.

### LLM API Calls

LLM API call counts are a planned comparison metric. The exact totals for the two 25-instance runs have not yet been established and are therefore not reported.

### Generation Wall-Clock Time

Generation wall-clock time measures the total elapsed generation time for each configuration, including time associated with unsuccessful generation attempts.

The baseline completed in 43 minutes and 34 seconds, while the enhanced configuration completed in 45 minutes and 20 seconds.

These measurements exclude subsequent SWT-Bench evaluation time.

## Generated Artifacts

The repository preserves the experiment's configurations, predictions, evaluation summaries, analysis scripts, and selected case studies.

### Test Generation Results

Generation artifacts are located under:

- `research_artifacts/generation/baseline25/`
- `research_artifacts/generation/enhanced25/`

Prediction files are located under:

- `research_artifacts/predictions/baseline25.swtbench.jsonl`
- `research_artifacts/predictions/enhanced25.swtbench.jsonl`

### SWT-Bench Evaluation Results

Aggregate evaluation artifacts are located under:

`research_artifacts/evaluation/`

Per-instance execution reports are located under:

`research_artifacts/instance_logs/`

These records support the reported issue reproduction outcomes and code coverage measurements.

### Case Studies

Selected baseline and enhanced patches and their test outputs are preserved under:

`research_artifacts/case_studies/`

The six selected instances allow individual differences in generated tests and reproduction outcomes to be examined.

### Analysis Results

The comparison scripts and generated CSV files are located under:

`research_artifacts/analysis/`

These files support the reported aggregate measurements and per-instance outcome comparisons.

## Test Quality Analysis

The enhanced configuration generated different patches from the baseline in all 21 instances evaluated by SWT-Bench.

However, differences in generated tests did not consistently translate into improved issue reproduction.

Three instances resolved by both configurations, two resolved only by the baseline, and one unresolved by both were selected for closer examination.

The case studies indicate that the enhanced prompt sometimes encouraged broader test scenarios, but these additional scenarios did not necessarily satisfy the precise reproduction requirements of the benchmark.

The results therefore suggest that increased code coverage should not be interpreted as equivalent to improved defect detection.

## Threats to Validity

The experiment has several limitations.

First, SWT-Bench's resolved/unresolved classification does not fully capture differences in the number, breadth, or quality of generated regression tests.

Second, the sample contains only 25 selected instances, limiting the generalizability of the findings to other software projects and defect types.

Third, four instances experienced generation failures in both configurations and could not be evaluated. Their potential reproduction outcomes remain unknown.

Fourth, the nondeterministic nature of LLM-generated outputs introduces possible run-to-run variation. Since each configuration was evaluated in one full run, repeated trials would be necessary to establish whether the observed differences are consistent.

Finally, all additional defect-pattern instructions were introduced together. The experiment therefore cannot isolate the contribution of individual defect patterns.

The experiment also did not independently measure silent-failure detection or false-positive rates. Consequently, conclusions about improvements in detecting subtle or silent software defects remain limited.

## Contributions

M. Kottal - Initial experiment design, experiment execution, evaluation analysis, and report writing. K. Gacek - Initial experiment design, experiment execution, evaluation analysis, and report writing.

## References

- [mini-SWE-agent](https://github.com/SWE-agent/mini-swe-agent)
- [SWT-Bench](https://github.com/logic-star-ai/swt-bench)
- [SWE-bench Lite dataset](https://huggingface.co/datasets/princeton-nlp/SWE-bench_Lite)
