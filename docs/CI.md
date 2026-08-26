# Continuous Integration

Pull requests and relevant pushes to `main` trigger focused workflows. No workflow requires AWS credentials; this repository validates configuration and build artifacts but does not plan, apply, publish images, or deploy infrastructure.

| Workflow | Triggered by | Checks |
|---|---|---|
| [Terraform CI](../.github/workflows/terraform-ci.yml) | Terraform files, TFLint config, or this workflow | `fmt`, `validate`, TFLint, advisory Checkov, summary |
| [Go CI](../.github/workflows/go-ci.yml) | Changes under `app/` or `app-no-db/` | `gofmt`, `go vet`, `go test` for both apps |
| [Docker CI](../.github/workflows/docker-ci.yml) | App, Dockerfile, Compose, or this workflow changes | Builds both application images without pushing |
| [Documentation CI](../.github/workflows/docs-ci.yml) | Markdown or documentation workflow changes | Markdown lint |

Terraform CI runs four checks in parallel and posts a combined report to the workflow run's summary page.

| Check | Tool | Blocking | What it catches |
|---|---|---|---|
| Formatting | `terraform fmt -check -recursive` | Yes | Inconsistent indentation/style |
| Validation | `terraform validate` | Yes | Syntax errors, invalid references, type mismatches |
| Linting | [TFLint](https://github.com/terraform-linters/tflint) + AWS ruleset | Yes | Naming conventions, undocumented/untyped variables, unused declarations, AWS-provider-specific mistakes |
| Security scan | [Checkov](https://www.checkov.io/) | No (advisory) | Misconfigurations against CIS/AWS security benchmarks (open security groups, missing encryption, etc.) |

**Why fmt/validate/tflint block the PR but checkov doesn't (yet):** this CI was added over code that predates any linting, so tflint and checkov initially surfaced a real backlog of findings on legacy resources. Rather than turning the PR red for pre-existing issues, both ran in report-only mode at first. TFLint's backlog (9 missing module version constraints, 1 unused variable) has since been triaged and fixed, so it's now blocking like fmt/validate. Checkov's backlog (43 findings, mostly security/compliance trade-offs) is still open — once triaged, flip its `continue-on-error: true` to `false` in the workflow to make it blocking too, the same way TFLint was promoted. That's the standard rollout pattern for introducing a new linter into an existing codebase: advisory first, blocking once clean.

A final `report` job aggregates all four results into one Markdown table in the run summary, and is the single job worth requiring as a branch protection check if you want PRs blocked on fmt/validate/tflint failures.

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

# Go checks
(cd app && test -z "$(gofmt -l .)" && go vet ./... && go test ./...)
(cd app-no-db && test -z "$(gofmt -l .)" && go vet ./... && go test ./...)

# Docker image builds
docker build --pull -t ip-reverser-ci ./app
docker build --pull -t ip-reverser-no-db-ci ./app-no-db

# Markdown lint (requires Node.js and npm)
npx --yes markdownlint-cli2 "**/*.md"
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
