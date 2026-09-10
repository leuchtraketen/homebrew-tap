<!-- Managed by lr-opencode-fork-updater -->
# lr-opencode

Precompiled OpenCode fork CLI for macOS and Linux (arm64 or x86-64 baseline).
Install: `brew install leuchtraketen/tap/lr-opencode`
Update: `brew upgrade leuchtraketen/tap/lr-opencode`

Binary version: `0.0.0-fork.917919f3b6a2`; Homebrew version: `0.0.386651208`.
Downloads only the selected platform archive, verified with its manifest SHA-256.
No build step or Node, Bun, or .NET installation is required.
Unsigned and not notarized. Existing OpenCode config, auth, data and state are shared.
The Homebrew launcher disables upstream automatic updates and directs `upgrade` to Homebrew.

Linux without Homebrew: download `install.sh` from this tap's default branch,
inspect it, then run `bash install.sh`. Run it again to update.
The installer follows `lr-opencode-channel.txt`, including fork prereleases.
The channel pins the release ID, tag and SHA-256 of the release's `SHA256SUMS` file.
Release assets and provenance: https://github.com/leuchtraketen/opencode/releases/tag/v0.0.0-fork.917919f3b6a2
