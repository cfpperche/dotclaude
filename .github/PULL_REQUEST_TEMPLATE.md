<!-- Thanks for the contribution! -->

## What

<!-- Concrete description of the change. What files? What behavior? -->

## Why

<!-- Motivation. Link to issue if applicable: "Closes #N" / "Relates to #N". -->

## How

<!-- Implementation notes if non-obvious. -->

## Test plan

- [ ] Ran `./scripts/doctor.sh` after the change — no new failures
- [ ] If the change adds shell scripts: `shellcheck` passes at error severity
- [ ] If the change adds JSON / YAML: validated locally
- [ ] If the change is stack-aware: tested against at least 2 stacks
- [ ] Idempotence verified: ran the affected script(s) twice

## Checklist

- [ ] No `.env`, `.credentials.json`, tokens, or keys in the diff
- [ ] No `git add -A` / `git add .` in shipped scripts
- [ ] No personality / personal preferences hardcoded into agent behavior
- [ ] No domain-specific logic that locks the agent to one stack/vendor
- [ ] Documentation updated if user-facing behavior changed
- [ ] Commit messages follow `type(scope): subject` convention

## Out of scope

<!-- Things explicitly NOT in this PR. Open follow-up issues if needed. -->
