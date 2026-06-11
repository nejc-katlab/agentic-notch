cask "agentdock" do
  version "0.1.0"
  sha256 "e519f13e3ec13f965e1978eebadf6e850d3f14b568abef6c092a0e8e8947281d"

  url "https://github.com/nejc-katlab/agentic-notch/releases/download/v#{version}/AgentDock-#{version}.zip"
  name "AgentDock"
  desc "Notch overlay showing your running AI coding agents"
  homepage "https://github.com/nejc-katlab/agentic-notch"

  depends_on macos: ">= :ventura"

  app "AgentDock.app"

  caveats <<~EOS
    AgentDock is not notarized (unsigned build). On first launch either
    right-click the app and choose Open, or clear the quarantine flag:

      xattr -dr com.apple.quarantine /Applications/AgentDock.app

    To connect your agents, run the hook installers from the repo:
      hooks/install.sh           # Claude Code
      hooks/install-codex.sh     # Codex CLI
      hooks/install-gemini.sh    # Gemini CLI
      hooks/install-opencode.sh  # OpenCode (experimental)
  EOS

  zap trash: "~/.agentdock"
end
