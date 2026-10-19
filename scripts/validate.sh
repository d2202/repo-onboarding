#!/bin/sh
# Both hosts refuse a skill silently if the contract below breaks, so check it before shipping:
# Codex requires non-empty `name` + `description` frontmatter (name <= 64 chars) and a parseable
# .codex-plugin/plugin.json; Claude Code requires the same frontmatter plus .claude-plugin/*.json.
set -e
cd "$(dirname "$0")/.."
fail=0

for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json; do
  node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" || { echo "invalid JSON: $f"; fail=1; }
done

node -e '
const fs = require("fs");
const p = "skills/repo-onboarding/SKILL.md";
const m = fs.readFileSync(p, "utf8").match(/^---\n([\s\S]*?)\n---\n/);
if (!m) { console.error("no YAML frontmatter in " + p); process.exit(1); }
const fm = m[1];
const name = (fm.match(/^name:[ \t]*(.+)$/m) || [])[1];
if (!name || !name.trim()) { console.error("frontmatter: name missing"); process.exit(1); }
if (name.trim().length > 64) { console.error("frontmatter: name over 64 chars (Codex limit)"); process.exit(1); }
const folded = /^description:[ \t]*[>|]/m.test(fm);
const inline = (fm.match(/^description:[ \t]*(.+)$/m) || [])[1];
const body = folded
  ? (fm.split(/^description:.*$/m)[1] || "").split(/\n(?=\S)/)[0]
  : inline;
if (!body || !body.trim()) { console.error("frontmatter: description empty (Codex hard-errors)"); process.exit(1); }
const skills = JSON.parse(fs.readFileSync(".codex-plugin/plugin.json", "utf8")).skills;
if (!skills || !fs.existsSync(skills.replace(/^\.\//, ""))) {
  console.error("codex plugin.json: skills path missing: " + skills); process.exit(1);
}
console.log("skill frontmatter + manifests OK");
' || fail=1

exit $fail
