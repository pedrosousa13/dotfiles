# CLAUDE.md

@~/.agents/AGENTS.md

## Claude-only: Delegate Retrieval to Haiku

**Cheap model moves bytes. Expensive model decides meaning.**

Default to delegating bulk retrieval to Haiku subagents:

```
Agent(subagent_type: "Explore", model: "haiku", prompt: "...")
```

Applies to: file sweeps, grep fan-out across many paths, log and build-output
scans, dependency or docs lookup, "where is X defined/used" questions.

Ask the subagent for raw excerpts with `file:line` locations, not for a
summary or a conclusion. Judgment stays on the main model.

Do it directly instead when:
- The source is small enough to read in one or two tool calls.
- Relevance needs judgment you can't specify up front.
- A miss is expensive: security review, migrations, debugging.

When you delegate, commit to it. Don't re-read what the subagent read.
