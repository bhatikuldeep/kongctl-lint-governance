# Team governance

For a platform team onboarding several teams onto one Konnect organisation. All names and values are synthetic (`team-a`, `team-b`); the onboarding format (`type: konnect.team`) is illustrative, so adapt the field names and formats to your own standards. Run every command from the **repository root**.

## What it checks

1. Each team's **onboarding file** is complete and well formed (`rulesets/onboarding-baseline.yaml`, plus `teams/<team>/onboarding-check.yaml` for group membership).
2. Every control plane carries **that team's** owner, cost centre, service ID and application ID as valid Konnect labels (`rulesets/resources-baseline.yaml` + the team's exact values).
3. The team stays in **its namespace** and **its approved resource types** (`teams/<team>/ruleset.yaml`).
4. The team's AI Gateway files also satisfy the [AI Gateway ruleset](../ai-gateway/ruleset.yaml), because each team ruleset extends it.

```text
onboarding/team-a.yaml ──lint──► rulesets/onboarding-baseline.yaml
team's kongctl files   ──lint──► teams/team-a/ruleset.yaml ──extends──► ai-gateway/ruleset.yaml
                                                           └─extends──► rulesets/resources-baseline.yaml
```

## Try it

```bash
make check
kongctl lint -f team-governance/samples/team-a/violations.yaml -r team-governance/teams/team-a/ruleset.yaml -F warn
kongctl lint -f team-governance/samples/team-a/ai-gateway-other-team.yaml -r team-governance/teams/team-a/ruleset.yaml -F warn
```

The last file is a sound AI Gateway config that uses another team's namespace: the AI Gateway rules pass, the team rules fail.

## Add a team

1. Add `onboarding/<team>.yaml` and lint it with `rulesets/onboarding-baseline.yaml`.
2. Copy `teams/team-b/` to `teams/<team>/` and replace the team name, owner, cost centre, IDs and approved resource types.
3. Review both in the same pull request (a code-owner rule on `onboarding/` and `teams/` helps).
4. Point that team's pipeline at its own ruleset:

```bash
kongctl lint -f . -R -r team-governance/teams/<team>/ruleset.yaml -F warn
kongctl plan --require-namespace=<team> -f . --mode apply --output-file plan.json
```

## Things to know

- **Choose the ruleset from the pipeline, never from the namespace inside the file.** `samples/team-a/impersonates-team-b.yaml` copies team-b's namespace and labels and passes team-b's rules. The platform team fixes each pipeline to its team's ruleset.
- **Label values must be identifiers**: letters, digits, `-`, `_`, `.`, at most 63 characters (`team-a-ops`, not "Team A Ops" or an email address). The baselines check this.
- **The team ruleset repeats values from the onboarding file.** Nothing links them, so review both together.
- Label rules cover `control_planes`. Add other resource types to the `given` lists in `rulesets/resources-baseline.yaml`.
