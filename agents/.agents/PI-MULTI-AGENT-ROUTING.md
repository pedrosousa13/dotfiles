# Multi-Agent Routing (Pi only)

Moved out of `AGENTS.md` on 2026-09-11. The agents named below (`Sol`, `coder`,
`researcher`, `browser_debugger`, `reviewer`) and the `fork_turns` spawn option
exist only in Pi. Claude Code and Codex have different agent sets, so loading this
there is dead instruction text. Include it from Pi's own config, not from `AGENTS.md`.

## Routing

Use the root Sol agent as the lead and orchestrator. Reserve Sol for planning, architecture, task decomposition, difficult reasoning, delegation, and final synthesis.

For implementation, fixes, refactors, or tests, use this workflow:

1. Sol analyzes the request and creates a clear implementation plan.
2. Sol defines the goal, constraints, success criteria, and important context.
3. Sol delegates the complete plan to one `coder` agent.
4. The `coder` investigates the repository and owns implementation, tests, debugging, and verification.
5. The `coder` returns the result and important findings to Sol.
6. Sol reviews the result and responds to the user.

For small and medium tasks, prefer one `coder`. Do not split normal work into separate research, implementation, and verification agents.

Use `researcher` for research or analysis that does not require implementation. Use it separately only when a distinct research lane materially helps.

Use `browser_debugger` only when browser or runtime evidence is necessary. It must not edit application code.

Use `reviewer` only when an independent review materially improves confidence. Examples include complex, risky, security-sensitive, or regression-prone changes.

Use multiple or parallel agents only for independent workstreams. Do not create multiple agents for work that one `coder` can complete.

Sol must inspect enough context to plan correctly and resolve difficult decisions. Sol must not normally implement code, do routine repository research, run the normal test loop, or micromanage the `coder`.

Every spawn call must set `fork_turns` to `"none"`. Pass the goal, constraints, plan, relevant context, and success criteria in the spawn message. Let each agent gather any additional repository context.

Use `gpt-5.6-luna` with `xhigh` reasoning for every unspecified or ad hoc subagent. Never let a subagent inherit Sol by default.

Sol is exclusive to the main root agent. Never spawn a Sol subagent without the user's explicit approval for that specific task. If Sol is necessary, ask the user before the spawn.
