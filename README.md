# repo-onboarding

A Claude Code skill for the first ten minutes in a repository you have never seen.

Ask "what is this?" and you normally get a paraphrased README. This skill instead
reads what actually executes — the Makefile and CI config — finds where execution
starts, and reports what does not add up.

## What it does

One recon pass, then a dense report:

**Stack · How to run · How to test · Entry points · External dependencies · What doesn't add up**

The last section is the point. On a real service it surfaced: a README documenting ten
make targets that no longer exist, a `pytest` config that silently ran zero tests, a
migration command pointing at a module absent from the repo, and secrets committed to
version control. None of that is findable by searching, because there is nothing to
search for.

It also names the repo's **generation rule** — the repeated shape a new unit of code
takes ("a UI section = two route files plus two registry edits"). That single line
turns later searches into a path instead of a scan.

At the end it offers to persist what it learned into `CLAUDE.md` — deliberately not the
whole report, only the parts that change what a future session does. Stack and versions
are excluded on purpose: they are one command away and rot first.

## Install

```
/plugin marketplace add d2202/repo-onboarding
/plugin install repo-onboarding
```

Or without the plugin system — copy `skills/repo-onboarding/SKILL.md` to
`~/.claude/skills/repo-onboarding/SKILL.md`.

## Use

Just ask, in English or Russian: "what is this?", "how do I run this?", "что тут
происходит?". The skill triggers on broad questions about the repo you are in. It also
triggers before edits in a directory with no `CLAUDE.md`.

## Optional

If the `codebase-memory` MCP server is installed, the skill uses its graph for entry
points and offers to index the repo at the end. Without it everything works the same
via `find` and `grep`.

## License

MIT
