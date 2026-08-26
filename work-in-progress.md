# Work In Progress

## Terraform

- [x] Fix the network topology so the ALB uses public subnets and the application Auto Scaling Group uses private subnets.
- [x] Remove public IP assignment from application instances in the launch template.
- [x] Rework module inputs in [main.tf](./main.tf) so compute receives separate subnet lists for load balancer and instances.
- [x] Simplify security group ownership so it is managed in one place instead of split across `compute`, `database`, and `security`.
- [x] Remove or make optional the bastion host and SSH ingress path if SSM-only access is the intended default.
- [x] Remove internet-wide SSH exposure from security groups.
- [ ] Decide whether the `security` module is still needed; remove it if its responsibilities are better handled inside the owning modules.
- [x] Replace tracked database credentials with a safer pattern such as AWS Secrets Manager or SSM Parameter Store.
- [x] Stop passing database credentials via EC2 user data in plaintext.
- [x] Replace the tracked `terraform.tfvars` with a sanitized example file and document how to provide real values locally.
- [x] Commit `.terraform.lock.hcl` so provider versions are consistent across local runs and CI.
- [x] Move CloudWatch resources out of `modules/cloudwatch/variables.tf` into `modules/cloudwatch/main.tf`.
- [x] Either wire the CloudWatch agent end to end or reduce the monitoring claims in the Terraform and documentation.
- [ ] Review whether the VPC endpoints are sufficient for SSM-only private-instance access, or whether additional endpoints are required for the chosen operating model.

## Application And Local Dev

- [x] Align [app/README.md](./app/README.md) with the actual application environment variables used by [app/main.go](./app/main.go).
- [x] Remove or implement the documented `/stats` endpoint.
- [ ] Fix the Docker run examples so they match the app's real configuration model.
- [x] Fix [app-no-db/Dockerfile](./app-no-db/Dockerfile) so it does not copy a missing `go.sum`.
- [x] Remove hardcoded local database credentials from [docker-compose.yml](./docker-compose.yml) and switch to `.env`-based local configuration.
- [ ] Add basic Go unit tests for the IP reversal and request handling paths in both sample apps.
- [ ] Make the main Dockerized app buildable, runnable, and ready for repeatable deployment from this repository.
- [ ] Review whether the app should remain a demo container consumer in Terraform or become the actual deployed workload.
- [ ] Improve Dockerfiles for cache efficiency, correctness, and smaller runtime images.
- [ ] Add container health checks and confirm they align with ALB and local Docker usage.
- [ ] Decide on a single configuration contract for the app, such as explicit env vars or a DSN, and use it consistently in code, Docker, Compose, and docs.
- [x] Add a `.env.example` or similar local-development template for app configuration.
- [ ] Validate the app container locally with `docker build` and a documented smoke test flow.

## Documentation

- [x] Update [README.md](./README.md) to match the actual deployed topology after the Terraform refactor.
- [x] Update [README.md](./README.md) and [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md) so the access model is consistent about SSM, SSH, and bastion usage.
- [x] Document the real secret-management approach once Terraform stops relying on committed passwords.
- [x] Clarify what the CloudWatch module currently does versus what is planned.
- [ ] Review committed debug logs and decide whether they should remain tracked or move to example snippets in documentation.
- [x] Add a short “known limitations” section so intentional demo tradeoffs are explicit.

## CI And Quality Gates

- [ ] Expand CI coverage beyond Terraform-only file changes.
- [ ] Add a Go validation workflow that runs formatting and `go test ./...` for `app` and `app-no-db`.
- [ ] Add Docker build validation for both application images.
- [ ] Add a Markdown lint or link-check step for documentation changes.
- [ ] Keep Checkov advisory only until findings are triaged, then convert it to blocking.
- [ ] Consider adding `terraform-docs` or `pre-commit-terraform` to keep module docs and local checks consistent.

## Suggested Order

- [x] Phase 1: Fix topology and security model, run validation and regression checks, then analyze and update the related documentation.
- [x] Phase 2: Remove plaintext secret handling, run validation and regression checks, then analyze and update the related documentation.
- [x] Phase 3: Repair CloudWatch and local app/dev workflows, run validation and regression checks, then analyze and update the related documentation.
- [ ] Phase 4: Make the app and Docker workflow buildable, consistent, and deployment-ready, run validation and regression checks, then analyze and update the related documentation.
- [ ] Phase 5: Expand CI and quality gates, run validation and regression checks, then analyze and update the related documentation.
- [ ] In every phase, treat testing, validation, and documentation review as part of the definition of done rather than final cleanup steps.

## Phase Exit Checks

- [x] Phase 1 exit checks: `terraform fmt -check -recursive`, `terraform validate`, targeted `tflint`, and a manual review of subnet and security-group relationships.
- [ ] Follow up on the skipped local `tflint` run once `tflint` is available in the environment.
- [x] Phase 2 exit checks: confirm no plaintext secrets remain in tracked files, Terraform inputs, Compose files, or user data; rerun Terraform validation and any affected app checks.
- [x] Phase 3 exit checks: validate CloudWatch-related Terraform, verify local app workflows still run, and confirm documentation examples still match the code.
- [ ] Phase 4 exit checks: `go test ./...`, `docker build` for both apps, Docker Compose validation, and a documented smoke test for the main app container.
- [ ] Phase 5 exit checks: verify all workflows pass, confirm new checks trigger on the intended file changes, and ensure local developer instructions match CI behavior.

## Branch And PR Conventions

- [x] Phase 1 branch name: `topology-changes`
- [x] Phase 2 branch name: `secret-handling`
- [x] Create each phase branch from `main` when implementation for that phase starts.
- [x] Phase 3 branch name: `cw-app-worflows`
- [ ] Phase 4 branch name: `app-in-docker`
- [ ] Phase 5 branch name: `ci-qa-unit-tests`
- [ ] Create each phase branch from `main` when implementation for that phase starts.
- [ ] Use short, clear commit messages for each commit.
- [ ] Use short PR titles.
- [ ] Keep PR descriptions short, but include the standard essentials: scope, main changes, validation performed, and any known follow-ups.
