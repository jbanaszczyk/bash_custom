# bash-customization

Portable bash customization for developer workstations and servers.

- Powerful file finder (`ffind`) - recursive search with content grep, case options, hidden file support
- Keyboard-driven navigation using [fzf](https://github.com/juniper/fzf) - fuzzy finder for interactive directory/file/history picking
- Syntax-highlighted file viewer (`list`) via [batcat](https://github.com/sharkdp/bat) (optional)
- Selenized Light theme (colors come from the terminal palette)

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

Deploy to multiple hosts in one command - `.` means local, the rest are SSH hosts.
Full steps are in each directory's `README.md` (sections *Initial deploy* and *Update*).

Initial deploy (once per host / account):

```bash
# 1. copy files, including .bashrc_ and dedup_history.sh (not in the default set)
cd bash_user && ./deploy.sh -f .bashrc_ -f dedup_history.sh . host1 host2

# 2-5. on each host
sudo apt install fzf bat bash-completion       # bat, bash-completion optional
cat ~/.bashrc_ >> ~/.bashrc && rm ~/.bashrc_   # .bashrc integration
~/dedup_history.sh                             # one-shot, removes itself
exec bash                                      # restart bash
```

Update after changes in the repo:

```bash
cd bash_user && ./deploy.sh . host1 host2      # default files only
exec bash
```

If `.bashrc_` changed, update the `Customization begin` ... `end` block in `~/.bashrc` by hand.

Other variants:

```bash
# root config: local + remote, requires sudo
cd bash_root && ./deploy_root.sh -f .bashrc_ -f dedup_history.sh . host1

# user config for the jenkins account on two hosts, requires sudo
cd bash_user && ./deploy.sh -u jenkins . host1
```

## History deduplication

`HISTCONTROL=erasedups` is set in `.bashrc_` - a repeated command removes its older copies
from the in-memory history. By default bash only *appends* new commands to `~/.bash_history` on exit,
so the file would keep the old copies. `.bashrc_` therefore sets an EXIT trap:

```bash
[[ -z $BASH_EXECUTION_STRING ]] && trap 'history -w; unset HISTFILE' EXIT
```

On exit the file is rewritten from the in-memory history (already deduplicated); `unset HISTFILE`
stops bash from appending the session again afterwards. Consequences:

- with several terminals open, the last one to exit wins - commands from the others can be lost
- killed sessions (closed window with ssh, SIGKILL) save nothing
- `exec bash` does not run the trap; it appends the session (a few duplicates, removed when the command is used again)
- `bash -i -c ...` (IDEs and tools reading the shell environment) does not load history, so the trap is not set there - otherwise it would empty the file

For history accumulated before this setting, run `dedup_history.sh` once during the initial deploy.

Editing `~/.bash_history` by hand: the EXIT trap would overwrite the file from memory and discard the edits.
After editing, reload the history in the same session (other open terminals still overwrite on exit):

```bash
vi ~/.bash_history
history -c; history -r    # clear in-memory history, read it from the file
```

## Features

### Prompt

- Hostname alias system (short display names per host)
- Git status segment: branch, staged/unstaged/untracked/conflict counts, stash indicator (`bash_user` only)
- Single-line prompt when not at `$HOME`, two-line when at `$HOME`
- Window (ssh session) title: `user@host_alias`
- Colors via ANSI 16 - Selenized values come from the terminal color scheme

### Navigation

Cohesive set of commands and keys for moving around the filesystem:

| Where to go              | bash_user                 | bash_root            |
|--------------------------|---------------------------|----------------------|
| up 1 level               | `..` or Ctrl+Page Up      | `..` or Ctrl+Page Up |
| up 2 levels              | `...`                     | `...`                |
| `$HOME`                  | `~`                       | `~`                  |
| current project          | `~~` (`$PROJECT_DIR`)     | -                    |
| git root / `$HOME` / `/` | `/`                       | `/` (always `/`)     |
| into a subdir            | Ctrl+Page Down (fzf)      | -                    |
| dir from .dir_history    | Page Up (fzf `dh`)        | -                    |
| type a path directly     | `autocd` (no `cd` needed) | -                    |

`bash_user` only: after every directory change, `./.direnv` is sourced if it is a regular file,
owned by you and executable (`chmod +x .direnv`). See `bash_user/README.md`.

### fzf utilities (`bash_user` only)

| Key / Command  | Description                                        |
|----------------|----------------------------------------------------|
| Ctrl+Page Down | interactively select and `cd` into a subdirectory  |
| Page Up        | pick from directory history (`dh`) and `cd` there  |
| Page Down      | command history picker (inserts into command line) |
| `list`         | interactively select a file to view                |
| `rm`           | interactive, safe file remove                      |
| `del`          | interactive, forced file remove (`rm -rf`)         |

### `netstat`

Wrapper with a sensible default: `netstat` with no arguments runs `netstat -ltnp` (listening TCP sockets with PIDs). Passes arguments through unchanged when provided.

Available in both `bash_user` and `bash_root`.

### `clip` (`bash_user` only)

`dir | clip` or `clip "text"` copies to the local clipboard - also from an ssh session.
Uses the OSC 52 escape sequence, supported by Kitty and Windows Terminal. Copy only, no paste.

### `load_completion`

Loads `/usr/share/bash-completion/bash_completion` if present. Called automatically in `bash_user/.bashrc_`. On systems where bash-completion is not sourced by default, run `load_completion` manually to enable tab-completion for commands.

```bash
sudo apt install bash-completion
```

### `ffind`

File finder inspired by `FFIND` from [TCC (Take Command Console)](https://jpsoft.com/) by JP Software. Available in both `bash_user` and `bash_root`.

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

ANSI 16 color scheme via `~/.dircolors` - follows the terminal palette (Selenized Light in Kitty / Windows Terminal).

Colors are for **grouping** only: one hue per file group, no bold-only differences.
Hues roughly follow the IntelliJ Selenized Light theme.

| Group                                                                    | ANSI       | IntelliJ analogy        |
|--------------------------------------------------------------------------|------------|-------------------------|
| directories                                                              | blue       | keywords, folder icons  |
| executables                                                              | green      | Run action              |
| symlinks                                                                 | cyan       | strings                 |
| source code (`.java .kt .js .ts .py .c .sh .sql` ...)                    | magenta    | function declarations   |
| config / data / docs (`.xml .json .yaml .conf .properties .md .txt` ...) | yellow     | metadata, annotations   |
| archives, images, audio, video (`.tar .zip .jar .png .mp4` ...)          | red        | -                       |
| compiled, logs, backups (`.class .o .so .pyc .log .bak .tmp` ...)        | gray       | comments, ignored files |
| broken symlinks                                                          | red bar    | -                       |
| setuid / setgid                                                          | yellow bar | -                       |

### Kitty

The repo does not set terminal colors. The palette comes from Kitty's `selenized-light.conf`
(font: CommitMonoV143). Prompt and `ls` colors use ANSI 16, so they follow the Kitty theme.
`list` (batcat `--theme=ansi`) and fzf (`--color=16` in `FZF_DEFAULT_OPTS`) do too.

### Windows Terminal

Settings: `Ctrl+,` → **Color schemes** → Add, or edit `settings.json`.

Font: install CommitMono per-user (right-click the `.ttf` → **Install for me**, no admin needed).
The `face` name must match the one shown in Settings → Appearance.

Profile:

```json
"font": {
    "face": "CommitMonoV143",
    "size": 11,
    "axes": { "wght": 450 },
    "features": { "ss01": 1, "ss02": 1, "ss03": 1, "ss04": 1, "ss05": 1, "cv06": 1 }
},
"colorScheme": "Selenized Light"
```

Color scheme (same values as Kitty's `selenized-light.conf`):

```json
{
  "name": "Selenized Light",
  "background": "#FBF3DB", "foreground": "#53676D",
  "cursorColor": "#53676D", "selectionBackground": "#CFCEBE",
  "black": "#E9E4D0",  "brightBlack": "#CFCEBE",
  "red": "#D2212D",    "brightRed": "#CC1729",
  "green": "#489100",  "brightGreen": "#428B00",
  "yellow": "#AD8900", "brightYellow": "#A78300",
  "blue": "#0072D4",   "brightBlue": "#006DCE",
  "purple": "#CA4898", "brightPurple": "#C44392",
  "cyan": "#009C8F",   "brightCyan": "#00978A",
  "white": "#909995",  "brightWhite": "#3A4D53"
}
```

> The ANSI palette drives all colors: prompt, `ls`, `list`, fzf.
