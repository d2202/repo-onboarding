---
name: repo-onboarding
description: >-
  Use whenever the user asks any broad, open question about the repository they are
  sitting in, rather than about a specific symbol or file. The question is usually
  short and casual: "what is this", "what is this project", "what's going on here",
  "what does this do", "what am I looking at", "explain this codebase", "explain this
  repo", "give me an overview", "walk me through this repo", "how do I run this",
  "how do I build this", "how do I get this running", "how is this set up", "where do
  I start", "help me get oriented", "onboard me", "I just cloned this", "first time in
  this repo", "get up to speed", "что тут происходит", "что это за проект", "что тут
  вообще", "разберись в репозитории", "как это запускается", "как это поднять",
  "онбординг", "первый раз в этом репо".
  Brevity is not a signal to answer casually — a two-word question about a whole repo
  is exactly this skill's case.

  Also use before changing or debugging code in a directory you have not worked in
  this session, when no CLAUDE.md or AGENTS.md describes it.

  If you are about to orient yourself by hand — listing files, reading the README,
  skimming git log — stop and use this skill instead; that IS this skill's job.

  Not for a single-symbol lookup ("where is function X"), a diff review, or a repo
  whose CLAUDE.md or AGENTS.md already answers the question.
---

# Repository Onboarding

Learn enough to run, test, and safely change the repo. Output is a chat summary;
a file is written only if the user says yes in step 4.

**Memory file** below means the file this host loads into every session: `CLAUDE.md`
under Claude Code, `AGENTS.md` under Codex. If the repo already contains the other
one, that existing file wins — write where the repo already keeps its instructions
rather than starting a second file.

## 1. One recon call

Run this as a single shell call (`Bash` in Claude Code, `shell` in Codex). Never read
a whole file; never enter `node_modules`, `vendor`, `dist`, `build`, `target`, `.venv`,
or lockfiles.

```bash
ls -A | head -40
head -40 README* 2>/dev/null
head -30 go.mod package.json pyproject.toml Cargo.toml pom.xml build.gradle 2>/dev/null
head -40 Makefile justfile Taskfile.yml 2>/dev/null
head -40 .gitlab-ci.yml Jenkinsfile .circleci/config.yml 2>/dev/null
find .github/workflows -name '*.y*ml' -exec head -40 {} + 2>/dev/null
find . -maxdepth 1 -name 'docker-compose*.y*ml' -exec head -30 {} + 2>/dev/null
find . -maxdepth 3 \( -name '.env*' -o -name '*example*' -o -name '*sample*' \) \
  -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -15
git log --oneline -15; git shortlog -sn HEAD | head -5
git log --since='3 months ago' --name-only --pretty=format: 2>/dev/null \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -10
ls CLAUDE.md AGENTS.md 2>/dev/null
```

Two shell traps this call already avoids — keep them avoided if you edit it: an
unmatched glob aborts the whole line under zsh (use `find -exec … +`), and `head`
or `git shortlog` with no argument blocks reading stdin (`git shortlog -sn HEAD`).

Makefile and CI are the truth about build/test/run commands — they are what actually
executes. README is a claim about the past; when they disagree, that disagreement is
a finding.

## 2. Entry points

Locate `main.*`, `cmd/`, `src/index.*`, route/handler registration, worker and cron
starts. If the codebase-memory MCP is available and already has the project
(`list_projects`), use `search_graph`; if the tool is absent or the project is not
indexed, one `find`/`grep` — its absence is normal, not an error. Do not index mid-pass — indexing costs
minutes and belongs in step 4, after the user has seen what the repo is.

Beyond location, name the **generation rule** if one exists: the repeated shape a new
unit of this codebase takes ("a UI section = `schema_routes.py` + `data_routes.py`,
plus edits to `app/routes.py` and `si_meta/routes.py`"). This is the single most
useful thing onboarding produces — it turns future search into a path instead of a
scan. If the repo has no such rule, say so rather than inventing one.

## 3. Report

Dense summary under these headings, dropping empty ones:

**Stack** · **How to run** · **How to test** · **Entry points** ·
**External dependencies** · **What doesn't add up**

Write the report in the language the user is speaking, headings included.

No directory trees, no file inventories, no README paraphrase. Every command quoted
must come from a file you actually read. Unknowns go under "Что не сходится" — never
fill a gap with a plausible guess.

Hunt for these specifically: commands in README missing from Makefile/CI; an example
config committed with its real counterpart absent (repo won't start as cloned); tests
requiring a live DB, network, or credentials; config naming services absent from
docker-compose; env vars with no default.

## 4. Offer to persist

Ask both questions in ONE turn — one `AskUserQuestion` call where the host has that
tool, otherwise a single plain-text message with the options numbered — then act on
the answers:

1. The memory file — wording depends on the `ls` result from step 1:
   - exists → "Append to the existing CLAUDE.md/AGENTS.md?" (append / leave it)
   - absent → "Create a CLAUDE.md (Claude Code) / AGENTS.md (Codex)?" (create / don't)
2. codebase-memory — ask ONLY if that MCP is available: "Проиндексировать репо в
   codebase-memory?" (index / skip). Mention it costs minutes. On yes,
   run `index_repository`; on no, never raise it again this session. If the MCP is
   not installed, ask about the memory file alone and say nothing about indexing.

Ask once, in the user's language. If both answers are no, drop the subject entirely.

If the sandbox refuses the write (Codex read-only or approval-gated), do not retry
with escalation on your own: print the exact block to paste and say which file it
belongs in.

### What goes into the memory file

Not the chat summary. This file loads into EVERY future session, so a line costs
tokens always and earns its place only by changing what the next session does. Aim
for 20-40 lines; past that, cut the least actionable section rather than trimming
every section evenly.

Write:
- the generation rule from step 2 — the highest-value line in the file. State what
  breaks when it is violated ("forget either external registration and the section
  never appears in the UI"); verify it holds across all instances before writing it,
  not just the one you read
- gotchas and negative knowledge: commands the README documents that do not exist,
  tests that silently run nothing, tooling referenced but absent
- the full run command including env vars
- non-obvious data layout (e.g. models split across two schemas of one DB)
- one line recording whether the repo is indexed in codebase-memory

Do NOT write: stack and versions (one command from the manifest, and first to rot),
inventories of sections/files/endpoints, CI details.

External hosts are the exception to that list: name one when it explains why the repo
will not build or start as cloned (a private package registry, a database that lives
only on a dev network). A host as trivia is noise; a host as the reason `poetry
install` fails belongs next to the run command.

Filter: nothing that a single command re-derives. Keep the file short enough that
drift from reality is visible — a bloated memory file becomes a README that lies,
except this one gets read as truth every session.

Appending adds only missing sections — never rewrite or reorder existing content.
Do not commit; leave that to the user.

## Limits

One pass per area; inconclusive means note it and move on, not dig. Monorepo: orient
at top level, then ask which package matters. Never invent a run command — its absence
is itself a finding.
