# Needs kongctl 1.18 or later. Nothing talks to Konnect. Run from the repository root.
L = kongctl lint -F warn
G = team-governance
pass = @$(L) -f $(1) -r $(2) >/dev/null 2>&1 && echo "ok   passes: $(1)" || { echo "FAIL expected pass: $(1)"; exit 1; }
fail = @! $(L) -f $(1) -r $(2) >/dev/null 2>&1 && echo "ok   fails:  $(1)" || { echo "FAIL expected findings: $(1)"; exit 1; }
.PHONY: demo check
demo:
	-kongctl lint -f ai-gateway/examples/wrong.yaml -r ai-gateway/ruleset.yaml -F warn
check:
	$(call pass,ai-gateway/examples/clean.yaml,ai-gateway/ruleset.yaml)
	$(call fail,ai-gateway/examples/wrong.yaml,ai-gateway/ruleset.yaml)
	$(call pass,$(G)/onboarding/team-a.yaml -f $(G)/onboarding/team-b.yaml,$(G)/rulesets/onboarding-baseline.yaml)
	$(call fail,$(G)/onboarding/examples/first-draft.yaml,$(G)/rulesets/onboarding-baseline.yaml)
	$(call pass,$(G)/onboarding/team-a.yaml,$(G)/teams/team-a/onboarding-check.yaml)
	$(call fail,$(G)/onboarding/examples/dangling-membership.yaml,$(G)/teams/team-a/onboarding-check.yaml)
	$(call fail,$(G)/onboarding/examples/foreign-group.yaml,$(G)/teams/team-a/onboarding-check.yaml)
	$(call pass,$(G)/samples/team-a/compliant.yaml,$(G)/teams/team-a/ruleset.yaml)
	$(call pass,$(G)/samples/team-b/compliant.yaml,$(G)/teams/team-b/ruleset.yaml)
	$(call fail,$(G)/samples/team-a/violations.yaml,$(G)/teams/team-a/ruleset.yaml)
	$(call fail,$(G)/samples/team-a/invalid-labels.yaml,$(G)/teams/team-a/ruleset.yaml)
	$(call fail,$(G)/samples/team-a/impersonates-team-b.yaml,$(G)/teams/team-a/ruleset.yaml)
	$(call pass,$(G)/samples/team-a/ai-gateway-compliant.yaml,$(G)/teams/team-a/ruleset.yaml)
	$(call fail,$(G)/samples/team-a/ai-gateway-other-team.yaml,$(G)/teams/team-a/ruleset.yaml)
