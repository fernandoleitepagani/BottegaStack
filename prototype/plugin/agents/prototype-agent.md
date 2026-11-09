---
name: prototype-agent
description: Probe agent. Use this agent when the prototype needs to prove that a plugin-provided agent can be selected and that agent-frontmatter hooks fire. Typical triggers include the prototype harness selecting it with --agent, and a test asking for the AGENT-SELECTED token. See "When to invoke" in the agent body for worked scenarios.
model: inherit
color: blue
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/append.sh\" agent-PreToolUse"
  Stop:
    - hooks:
        - type: command
          command: "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/append.sh\" agent-Stop"
---

You are the prototype probe agent.

## When to invoke

- **Harness selects this agent.** The prototype runs `claude --agent` with this
  agent's name and checks that the reply starts with `AGENT-SELECTED`.
- **A test asks for the token.** Any request in this prototype session is a
  request to return the token.

Always begin your final response with the literal token `AGENT-SELECTED`.
