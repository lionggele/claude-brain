---
name: brain-agent-design
description: Design AI agent systems, tool schemas, multi-agent orchestration, and MCP servers. Use when building agentic workflows, tool-using LLM systems, or Claude Code extensions.
---

# Agent Design

When the user needs to build an agent system, MCP server, or multi-agent workflow:

## Step 1: Choose the Pattern

### Single Agent (start here)

```
User -> Agent -> [Tool A, Tool B, Tool C] -> Response
```

Best for: Most tasks. One LLM with access to tools.

### Router Agent

```
User -> Router Agent -> Agent A (code)
                     -> Agent B (research)
                     -> Agent C (data)
```

Best for: Distinct task types that need specialized prompts/tools.

### Orchestrator-Worker

```
User -> Orchestrator -> Worker 1 (parallel)
                     -> Worker 2 (parallel)
                     -> Worker 3 (parallel)
        Orchestrator <- [results merged]
```

Best for: Tasks that can be parallelized (multi-file edits, bulk analysis).

### Pipeline (sequential)

```
User -> Agent 1 (plan) -> Agent 2 (build) -> Agent 3 (review) -> Result
```

Best for: Workflows where each step depends on the previous.

## Step 2: Design Tool Schemas

Every tool needs:
1. A clear, specific name (verb_noun: `search_documents`, `create_file`)
2. A description that tells the LLM WHEN to use it
3. Typed parameters with descriptions
4. Defined error responses

```python
# FastAPI tool endpoint
from pydantic import BaseModel, Field

class SearchDocumentsInput(BaseModel):
    query: str = Field(..., description="Natural language search query")
    filters: dict | None = Field(None, description="Optional metadata filters")
    top_k: int = Field(5, ge=1, le=20, description="Number of results")

class SearchDocumentsOutput(BaseModel):
    results: list[DocumentResult]
    total: int
```

```typescript
// MCP tool schema
{
  name: "search_documents",
  description: "Search the document store using semantic similarity. Use when the user asks about specific topics or needs information from uploaded documents.",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string", description: "Natural language search query" },
      top_k: { type: "number", default: 5, description: "Number of results" }
    },
    required: ["query"]
  }
}
```

## Step 3: Build MCP Servers

MCP (Model Context Protocol) is the standard for extending Claude Code.

### Python MCP Server (FastMCP)

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
async def search_docs(query: str, top_k: int = 5) -> str:
    """Search documents by semantic similarity.

    Use when the user asks about specific topics from the knowledge base.
    """
    results = await vector_store.search(query, top_k=top_k)
    return format_results(results)

@mcp.resource("docs://{doc_id}")
async def get_document(doc_id: str) -> str:
    """Get a specific document by ID."""
    doc = await db.get(doc_id)
    return doc.content
```

### Register in Claude Code

```json
// ~/.claude/settings.json -> mcpServers
{
  "my-server": {
    "command": "python",
    "args": ["-m", "my_mcp_server"],
    "env": {
      "DATABASE_URL": "..."
    }
  }
}
```

## Step 4: Agent Prompt Design

### System Prompt Structure

```
ROLE: What the agent is and its expertise
TOOLS: When to use each tool (critical for tool selection)
CONSTRAINTS: What the agent must NOT do
OUTPUT: Expected response format
EXAMPLES: 1-2 examples of ideal behavior
```

### Key Rules

- **Tool descriptions > system prompts** for tool selection
- Give the LLM explicit decision criteria: "Use tool X WHEN condition Y"
- Always include error handling guidance: "If tool X fails, try Y"
- Limit tools to 10-15 per agent (more = worse selection)
- Use structured output (JSON) for agent-to-agent communication

## Step 5: Multi-Agent Communication

```python
# Agent-to-agent message format
@dataclass(frozen=True)  # Immutable
class AgentMessage:
    role: str           # "planner", "builder", "reviewer"
    content: str        # The actual message
    artifacts: dict     # Files, code, decisions produced
    metadata: dict      # Timing, token usage, model used
```

### Orchestration Patterns

```python
# Parallel execution with result merging
import asyncio

async def orchestrate(task: str) -> str:
    plan = await planner.run(task)

    # Parallel workers
    subtasks = plan.split_into_subtasks()
    results = await asyncio.gather(
        *[worker.run(st) for st in subtasks]
    )

    # Review and merge
    merged = await reviewer.run(results)
    return merged
```

## Step 6: Evaluation and Observability

- Log every tool call: input, output, latency, tokens
- Track success rate per tool
- Monitor retry loops (agent stuck = bad tool description)
- Set max iterations (prevent infinite loops)
- Cost tracking: tokens per task completion

```python
# Minimal agent observability
import logging
import json

logger = logging.getLogger("agent")

def log_tool_call(tool_name: str, input_data: dict, output: str, latency_ms: float):
    logger.info(json.dumps({
        "event": "tool_call",
        "tool": tool_name,
        "input": input_data,
        "output_length": len(output),
        "latency_ms": latency_ms,
    }))
```

## Common Mistakes

- Too many tools -> agent can't choose correctly
- Vague tool descriptions -> wrong tool selected
- No error handling -> agent crashes on tool failure
- No iteration limit -> infinite loops burn tokens
- Shared mutable state between agents -> race conditions
- Synchronous where async would work -> slow orchestration
