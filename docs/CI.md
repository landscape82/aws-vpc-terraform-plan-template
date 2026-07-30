# Continuous Integration

Every pull request against `main` that touches `.tf`/`.tfvars` files triggers [`.github/workflows/terraform-ci.yml`](../.github/workflows/terraform-ci.yml), which runs four checks in parallel and posts a combined report to the workflow run's summary page (no AWS credentials required — nothing here plans or applies).

| Check | Tool | Blocking | What it catches |
|---|---|---|---|
| Formatting | `terraform fmt -check -recursive` | Yes | Inconsistent indentation/style |
| Validation | `terraform validate` | Yes | Syntax errors, invalid references, type mismatches |
| Linting | [TFLint](https://github.com/terraform-linters/tflint) + AWS ruleset | No (advisory) | Naming conventions, undocumented/untyped variables, unused declarations, AWS-provider-specific mistakes |
| Security scan | [Checkov](https://www.checkov.io/) | No (advisory) | Misconfigurations against CIS/AWS security benchmarks (open security groups, missing encryption, etc.) |

**Why fmt/validate block the PR but tflint/checkov don't (yet):** this is the first CI pass added over code that predates any linting, so tflint and checkov are expected to surface a real backlog of findings on legacy resources. Rather than turning the PR red for pre-existing issues, they run in report-only mode. Once that backlog is triaged, flip `continue-on-error: true` to `false` on those two jobs in the workflow to make them blocking too — that's the standard rollout pattern for introducing a new linter into an existing codebase.

A final `report` job aggregates all four results into one Markdown table in the run summary, and is the single job worth requiring as a branch protection check if you want PRs blocked on fmt/validate failures.

## Running the same checks locally before pushing

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate

# Requires https://github.com/terraform-linters/tflint
tflint --init
tflint --recursive

# Requires: pip install checkov
checkov -d . --framework terraform --compact
```

## Helpful External Tools for Terraform Development

Tools worth knowing about beyond what's wired into CI here:

| Tool | Purpose |
|---|---|
| [`terraform-docs`](https://terraform-docs.io/) | Auto-generates a module's Inputs/Outputs/Resources reference table directly from its `.tf` files — the standard way public Terraform Registry modules document themselves |
| [`tflint`](https://github.com/terraform-linters/tflint) | Linting beyond what `terraform validate` covers — naming conventions, deprecated syntax, provider-specific best practices via rulesets like `tflint-ruleset-aws` |
| [`checkov`](https://www.checkov.io/) / [Trivy](https://aquasecurity.github.io/trivy/) | Static security and compliance scanning against CIS benchmarks and cloud provider best practices |
| [`infracost`](https://www.infracost.io/) | Shows estimated monthly cost impact of a Terraform plan/diff, often as a PR comment |
| [`pre-commit-terraform`](https://github.com/antonbabenko/pre-commit-terraform) | Wires `fmt`/`validate`/`tflint`/`docs` into git pre-commit hooks so issues are caught before a PR even opens |
| [`tenv`](https://github.com/tofuutils/tenv) (formerly `tfenv`) | Manages multiple installed Terraform/OpenTofu versions per project |
| [Atlantis](https://www.runatlantis.io/) / Terraform Cloud | Automates `plan`/`apply` as PR comments/checks for team workflows — beyond the scope of a single-maintainer template like this one, but the natural next step for a shared repo |
