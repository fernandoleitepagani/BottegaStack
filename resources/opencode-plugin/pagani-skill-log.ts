import { access, appendFile, mkdir, readFile } from "node:fs/promises";
import { basename, join } from "node:path";
import { Plugin } from "@opencode/plugin";

const LOG_DIRECTORY = "pagani";
const LOG_FILE = "skill-usage.tsv";

// Only log inside projects that look like PaganiStack projects. Otherwise we
// would create a `pagani/` directory in every unrelated repository.
async function isPaganiProject(directory: string): Promise<boolean> {
  try {
    await access(join(directory, "pagani", "jobs"));
    return true;
  } catch {
    // Fall through to the AGENTS.md check.
  }
  try {
    const agents = await readFile(join(directory, "AGENTS.md"), "utf8");
    return agents.includes("PaganiStack");
  } catch {
    return false;
  }
}

function skillName(input: unknown): string {
  if (input !== null && typeof input === "object") {
    const record = input as Record<string, unknown>;
    for (const key of ["name", "skill", "command"]) {
      const value = record[key];
      if (typeof value === "string" && value.trim() !== "") {
        return value.trim();
      }
    }
  }
  return "unknown";
}

export default Plugin.define({
  id: "pagani-skill-log",
  async setup(ctx) {
    await ctx.tool.hook("execute.after", async (event) => {
      if (event.tool !== "skill") return;

      try {
        const projectDirectory = ctx.location.project?.directory ?? ctx.location.directory;
        if (!(await isPaganiProject(projectDirectory))) return;

        const directory = join(ctx.location.directory, LOG_DIRECTORY);
        const row = `${new Date().toISOString()}\t${basename(projectDirectory)}\t${skillName(event.input)}\n`;

        await mkdir(directory, { recursive: true });
        await appendFile(join(directory, LOG_FILE), row, "utf8");
      } catch {
        // Logging must never break a tool call.
      }
    });
  },
});
