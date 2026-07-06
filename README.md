# PsPrompt

A PowerShell profile built around a custom prompt that stays useful instead of decorative: cross-session command numbering, relative path display, and inline git branch/status coloring — plus a small set of supporting utilities (colorized `ls`, git shortcuts, cross-session history).

## What's in the box

`Microsoft.PowerShell_profile.ps1` — drop-in replacement for your `$PROFILE`.

### The prompt

```
[7853] ~/local/repos/PSPrompt (master) [22:05:41]
λ
```

- **`[7853]`** — a command counter that persists across every session, not just the current one. Most PowerShell prompts either omit a counter or reset it to 1 on every new shell; this one reads PSReadLine's saved history file so the number keeps climbing for as long as you've been using the machine.
- **`~/local/repos/PSPrompt`** — current path, shown relative to `$HOME` when inside it.
- **`(master)`** — current git branch, shown only inside a repo. Green if clean, red if there are uncommitted changes (`git status --porcelain`).
- **`[22:05:41]`** — wall clock.
- **`λ`** — prompt character on its own line, so the command you type starts at column 0 regardless of how long the rest of the prompt got.

The cross-session counter is cached rather than re-read on every keystroke: it reads the history file's line count once at shell startup, then increments in memory for the rest of the session. On a history file with several thousand entries this is the difference between a one-time cost at launch and a full file re-parse before every single prompt render.

### Supporting utilities

| Command | Does |
|---|---|
| `ls` | Colorized directory listing — blue for folders, colored by extension for files (executables, config/data formats, build artifacts, source code, project files) |
| `l` | Alias for `ls` |
| `h` | Prints command history, cross-session, zero-based numbering |
| `gs` | `git status -s` |
| `gacp "message"` | `git add -A`, `git commit -m "message"`, `git push` — skips the push if the commit failed |
| `gp` | `git push` |
| `gll` | `git log --oneline --graph --decorate -20` |
| `which <name>` | Resolves a command the way bash's `which` does — shows type, source, and definition, since `Get-Command` covers aliases and functions as well as executables |
| `rmrf` | `Remove-Item -Recurse -Force`, for muscle memory coming from `rm -rf` |

A `trap` on `CommandNotFoundException` also replaces PowerShell's default error block for typos with a single clean line: `<command> not found`.

## Install

```powershell
cp Microsoft.PowerShell_profile.ps1 $PROFILE
. $PROFILE
```

Check which profile path applies to your shell first if you run both Windows PowerShell 5.1 and PowerShell 7+ — they use different `$PROFILE` locations, and this file needs to be in both if you switch between them.

## Requirements

- PSReadLine (ships with Windows PowerShell 5.1+ and PowerShell 7+)
- Git, for the branch/status segment and the `g*` shortcuts (silently omitted outside a repo)
- [PsBangHistory](https://github.com/cschladetsch/PsBangHistory) — the prompt's cross-session counter reads `Get-BangHistoryBuffer`, defined there. Update the dot-source path near the top of the profile to wherever you've cloned it.

## License

MIT