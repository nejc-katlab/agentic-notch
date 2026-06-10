import fs from "node:fs"
import os from "node:os"
import path from "node:path"

const root = path.join(os.homedir(), ".agentdock", "opencode")

export const AgentDock = async ({ directory }) => {
  fs.mkdirSync(root, { recursive: true })
  const cwd = directory || process.cwd()
  const project = path.basename(cwd)

  const write = (sessionId, state, activity, needsAttention) => {
    if (!sessionId) return
    const record = {
      tool: "opencode",
      sessionId,
      state,
      project,
      cwd,
      activity,
      needsAttention,
      ts: Date.now() / 1000,
    }
    const target = path.join(root, `${sessionId}.json`)
    try {
      fs.writeFileSync(`${target}.tmp`, JSON.stringify(record))
      fs.renameSync(`${target}.tmp`, target)
    } catch {}
  }

  const remove = (sessionId) => {
    if (!sessionId) return
    try {
      fs.unlinkSync(path.join(root, `${sessionId}.json`))
    } catch {}
  }

  return {
    "tool.execute.before": async (input) => {
      write(input?.sessionID, "working", `Running ${input?.tool ?? "tool"}`, false)
    },
    "tool.execute.after": async (input) => {
      write(input?.sessionID, "working", `Finished ${input?.tool ?? "tool"}`, false)
    },
    "permission.asked": async (input) => {
      write(input?.sessionID, "needs-permission", "Needs permission", true)
    },
    "permission.replied": async (input) => {
      write(input?.sessionID, "working", "Working", false)
    },
    event: async ({ event }) => {
      const sid = event?.properties?.sessionID
      if (event?.type === "session.created") write(sid, "working", "Session started", false)
      if (event?.type === "session.idle") write(sid, "idle", "Turn ended", false)
      if (event?.type === "session.deleted") remove(sid)
    },
  }
}
