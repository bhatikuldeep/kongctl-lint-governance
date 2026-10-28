# Kong Configuration Lint Rulesets: AI Gateway, MCP and Team Governance

Reusable, ready-to-run `kongctl lint` rulesets for Kong declarative configuration. Detect security risks, cost-control gaps and ownership problems before configuration changes reach Konnect.

## Overview

Configuration linting gives an automated, repeatable check against a defined set of engineering and security standards. It runs during development and pull-request review, so mistakes that are easy to miss by eye (an MCP server with no tool access list, prompt logging switched on, a literal secret, a model with no token cap) fail the build instead of reaching an environment.

This repository provides two sets of rulesets that work together.

| Ruleset | Configuration covered | Command | Rules |
|---|---|---|---:|
| [`ai-gateway/ruleset.yaml`](ai-gateway/ruleset.yaml) | Kong AI Gateway 2.x models, agents, **MCP servers**, policies, auth strategies and providers | `kongctl lint` | 80 |
| [`team-governance/`](team-governance/README.md) | Team onboarding for a shared Konnect organisation: onboarding file, mandatory ownership labels, namespace and resource-type scope per team | `kongctl lint` | 2 baselines + 1 short ruleset per team |

The two fit together: each team ruleset extends the AI Gateway ruleset, so one lint run answers both "is this configuration sound?" and "is it this team's, and within its scope?".

```text
team's kongctl files ──► kongctl lint -r team-governance/teams/<team>/ruleset.yaml
                          ├─ ai-gateway/ruleset.yaml             is the config sound?
                          └─ team rules (extend the baseline)    is it this team's, in scope?
                       ──► kongctl plan --require-namespace=<team>    second guard, read-only
                       ──► kongctl apply, as the team's system account   Konnect roles decide what is allowed
```

Lint is early, readable feedback. The namespace flag and the system account's permissions are what enforce.

## Getting started

### 1. Install the tool

- [kongctl](https://github.com/Kong/kongctl) version 1.18 or later.
- `make` for the helper targets (linting itself needs only kongctl).

The rulesets run locally. No Konnect account or credentials are required.

### 2. Clone the repository and run the examples

```bash
git clone https://github.com/bhatikuldeep/kongctl-lint-governance.git
cd kongctl-lint-governance

make demo     # lint a deliberately bad AI Gateway file and show the findings
make check    # self-test: good examples must pass, bad ones must fail
```

### 3. Lint a configuration file

```bash
kongctl lint -f ai-gateway/examples/wrong.yaml -r ai-gateway/ruleset.yaml
```

A typical finding looks like this:

```text
ai-gateway/examples/wrong.yaml:45:1:  [error] MCP server has no access.default_tool_acls (unlisted tools stay open).
ai-gateway/examples/wrong.yaml:48:53: [error] MCP payload logging is enabled.
ai-gateway/examples/wrong.yaml:13:53: [error] Target allows client-supplied credentials (allow_auth_override: true).
```

Each finding identifies the file, line, column, severity and reason. Every rule has a stable id (`aigw-*`) that you can cite in review comments.

### 4. Interpret the results

| Severity | Interpretation | Default outcome |
|---|---|---|
| `error` | A significant issue that should be resolved before deployment. | Fails the lint command. |
| `warn` | A potentially unsafe or fragile configuration that needs remediation or documented acceptance. | Does not fail unless `-F warn` is set. |
| `info`, `hint` | A recommendation or prompt for an engineering decision. | Does not fail. |

A compliant configuration exits with code `0`, even with `-F warn`:

```bash
kongctl lint -f ai-gateway/examples/clean.yaml -r ai-gateway/ruleset.yaml -F warn
```

### 5. Apply linting to your own configuration

| Requirement | Command or option |
|---|---|
| Lint AI Gateway 2.x configuration | `kongctl lint -f <file-or-directory> -r ai-gateway/ruleset.yaml` |
| Recursively lint a directory | Add `-R`. |
| Fail on warnings | Add `-F warn` (`--fail-severity`). |
| Display only failures | Add `-D` (`--display-only-failures`). |
| Read configuration from standard input | `cat config.yaml \| kongctl lint -f - -r <ruleset>` |
| Machine-readable output | Add `-o json`; each result has `rule_id`, `severity`, `file` and `line`. |
| Turn a rule off or change its severity | Extend the ruleset and override by id (below). |
| Govern several teams | See [team-governance](team-governance/README.md). |

To change a rule without editing the shared file:

```yaml
# my-ruleset.yaml
extends: [ai-gateway/ruleset.yaml]
rules:
  aigw-model-owner-label: off      # or: warn / error
```

`extends` paths resolve from the directory you run `kongctl` in, so run from the repository root. A wrong path only logs `cannot open external ruleset` and the run continues **without those rules, with exit code 0**. Keep a known-bad file in CI and assert that lint fails on it (see `make check`).

**Recommended rollout:** enforce errors first and remediate the findings, review warnings with their owners, then introduce `-F warn` when the team is ready for the stricter policy.

## What the AI Gateway ruleset covers

| Area | Examples |
|---|---|
| **MCP servers** | authentication required, tools denied by default, no tool arguments in logs, audit logging, upstream TLS, ACL attribute and claim settings, allowed protocol versions |
| Authentication | auth strategy on models and agents, OIDC issuer, audience and TLS verification, hidden credentials |
| Secrets | no literal provider, Redis or cloud secrets (use `!secret` or a vault reference), credential expiry |
| Data protection | prompts and responses not logged, guardrails fail closed |
| Cost control | `max_tokens` and prices on every target, token-based rate limits, request size cap |
| Resilience | bounded retries, failover, circuit breaker, cache never blocks inference |
| Ownership | namespace on every file, owner and status labels |
| Observability | Prometheus and OpenTelemetry settings |

## Limits

- `kongctl lint` reads each file as written. It does not expand `!file`, `!ref` or `_templates`, and cannot run custom JavaScript functions. Built-in functions cover the rules here.
- A missing ruleset in `extends` does not fail the run (see above), so test that your rules load.
- Rules see one file at a time, so cross-file checks (such as "this policy is attached to a model") need a different tool.
- Lint is feedback, not a gate: anyone who can call kongctl directly can skip it. Namespace flags and Konnect roles on the system account do the enforcing.

## Next

| Document | Contents |
|---|---|
| [team-governance/README.md](team-governance/README.md) | Onboarding a team, per-team rulesets, why the pipeline (not the file) picks the ruleset. |
| [ai-gateway/ruleset.yaml](ai-gateway/ruleset.yaml) | Every rule with its id, severity and plain-English description. |

### Related references

- [`kongctl lint`](https://developer.konghq.com/kongctl/lint/): Kong configuration linting reference.
- [Declarative configuration with kongctl](https://developer.konghq.com/kongctl/declarative): namespaces, `!secret`, `--require-namespace`.
- [vacuum rules](https://quobix.com/vacuum/rules/): supported ruleset syntax and validation functions.

---

**Project status:** These rulesets are opinionated defaults, supplied as-is. They are a personal project, not a Kong product feature, and do not replace `kongctl plan`, platform permissions, application-specific testing or a security review. All examples are synthetic.

Licensed under the [Apache License 2.0](LICENSE).
