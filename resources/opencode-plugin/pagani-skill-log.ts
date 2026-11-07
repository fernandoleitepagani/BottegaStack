import { appendFile, mkdir } from "node:fs/promises";
import { basename, join } from "node:path";
import { Plugin } from "@opencode/plugin";

const LOG_DIRECTORY = "pagani";
const LOG_FILE = "skill-usage.tsv";

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
        const directory = join(ctx.location.directory, LOG_DIRECTORY);
        const projectDirectory = ctx.location.project?.directory ?? ctx.location.directory;
        const row = `${new Date().toISOString()}\t${basename(projectDirectory)}\t${skillName(event.input)}\n`;

        await mkdir(directory, { recursive: true });
        await appendFile(join(directory, LOG_FILE), row, "utf8");
      } catch {
        // Logging must never break a tool call.
      }
    });
  },
});
