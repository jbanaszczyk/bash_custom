# bash-customization

Portable bash customization for developer workstations and servers.

- Powerful file finder (`ffind`) - recursive search with content grep, case options, hidden file support
- Keyboard-driven navigation using [fzf](https://github.com/juniper/fzf) - fuzzy finder for interactive directory/file/history picking
- Syntax-highlighted file viewer (`list`) via [batcat](https://github.com/sharkdp/bat) (optional)
- Solarized Light theme

## Repository structure

```
bash_user/          non-root user configuration (requires fzf)
bash_root/          root / service account configuration (no fzf)
```

Each directory is self-contained and ships with its own `README.md` and `deploy*.sh`.

## Requirements

- `bash_user`: `fzf` - fuzzy finder for interactive navigation (`sudo apt install fzf`)
- `bash_user`: `batcat` - syntax-highlighted file viewer, optional (`sudo apt install bat`)
- `bash_root`: no extra dependencies

## Quick start

Deploy to multiple hosts in one command - `.` means local, the rest are SSH hosts:

```bash
# Deploy user config: local + two remote hosts at once
cd bash_user && ./deploy.sh . host1 host2

# Deploy root config: local + remote, requires sudo
cd bash_root && ./deploy_root.sh . host1

# Deploy user config to jenkins account on two hosts, requires sudo
cd bash_user && ./deploy.sh -u jenkins . host1
```

## History deduplication

`HISTCONTROL=erasedups` is set in `.bashrc_` - new commands deduplicate against history on entry.

For existing history accumulated before this setting, run `dedup_history.sh` once after the first deploy.

## Features

### Prompt

- Hostname alias system (short display names per host)
- Git status segment: branch, staged/unstaged/untracked/conflict counts, stash indicator (`bash_user` only)
- Single-line prompt when not at `$HOME`, two-line when at `$HOME`
- Window (ssh session) title: `user@host_alias`
- Colors via ANSI 16 - Solarized values come from the terminal color scheme

### Navigation

Cohesive set of commands and keys for moving around the filesystem:

| Where to go              | bash_user            | bash_root            |
|--------------------------|----------------------|----------------------|
| up 1 level               | `..` or Ctrl+Page Up | `..` or Ctrl+Page Up |
| up 2 levels              | `...`                | `...`                |
| `$HOME`                  | `~`                  | `~`                  |
| git root / `$HOME` / `/` | `/`                  | `/` (always `/`)     |
| into a subdir            | Ctrl+Page Down (fzf) | -                    |
| dir from .dir_history    | Page Up (fzf `dh`)   | -                    |

### fzf utilities (`bash_user` only)

| Key / Command  | Description                                        |
|----------------|----------------------------------------------------|
| Ctrl+Page Down | interactively select and `cd` into a subdirectory  |
| Page Up        | pick from directory history (`dh`) and `cd` there  |
| Page Down      | command history picker (inserts into command line) |
| `list`         | interactively select a file to view                |
| `rm`           | interactive, safe file remove                      |
| `del`          | interactive, forced file remove (`rm -rf`)         |

### `ffind`

TCC-inspired file finder. Available in both `bash_user` and `bash_root`.

```
ffind [-sIibH] [-t "pattern"] [dir] "filename_pattern"
```

| Option         | Description                               |
|----------------|-------------------------------------------|
| `-s`           | recursive                                 |
| `-t "pattern"` | search file contents (regex)              |
| `-i`           | case-insensitive content search           |
| `-b`           | bare output (paths only, no file content) |
| `-H`           | include hidden files/dirs                 |
| `-I`           | case-insensitive filename match           |

Note: always quote glob patterns - `ffind "*.java"` not `ffind *.java`.

### `ls` colors

Solarized Light 256-color scheme via `~/.dircolors`.
256-color values are hardcoded - independent of the terminal palette.

| Color             | Files                                                           |
|-------------------|-----------------------------------------------------------------|
| blue (33)         | directories                                                     |
| orange bold (166) | symlinks                                                        |
| green (64)        | executables                                                     |
| cyan (37)         | source code (`.java .kt .js .ts .py .c .cpp .sh .sql` ...)      |
| violet (61)       | archives (`.tar .zip .jar .war` ...)                            |
| dim (245)         | config/data (`.xml .json .yaml .yml .conf .properties .md` ...) |
| dark (240)        | compiled artifacts (`.class .o .so .pyc`), logs, backups        |

### Windows Terminal

Settings: `Ctrl+,` → **Color schemes** → Add, or edit `settings.json`.

Profile:

```json
"font": {
"face": "JetBrains Mono",
"size": 12
},
"colorScheme": "Solarized Light (fixed)"
```

Color scheme:

```json
{
  "name": "Solarized Light (fixed)",
  "background": "#FEF8E5",
  "foreground": "#3B3F42",
  "cursorColor": "#3B3F42",
  "selectionBackground": "#E7EFEC",
  "black": "#073642",
  "blue": "#268BD2",
  "brightBlack": "#002B36",
  "brightBlue": "#839496",
  "brightCyan": "#93A1A1",
  "brightGreen": "#586E75",
  "brightPurple": "#6C71C4",
  "brightRed": "#CB4B16",
  "brightWhite": "#FDF6E3",
  "brightYellow": "#657B83",
  "cyan": "#2AA198",
  "green": "#859900",
  "purple": "#D33682",
  "red": "#DC322F",
  "white": "#EEE8D5",
  "yellow": "#B58900"
}
```

> ANSI palette affects prompt colors.
> `.dircolors` uses 256-color - unaffected by palette.
