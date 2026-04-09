# bash_user

Non-root user bash customization. Requires `fzf`.

## Requirements

```bash
sudo apt install fzf
```

## Files

| File               | Description                                |
|--------------------|--------------------------------------------|
| `.bashrc_`         | customization block — append to `.bashrc`  |
| `.bash_prompt`     | prompt with git segment and hostname alias |
| `.bash_aliases`    | aliases and small functions                |
| `.bash_functions`  | fzf-powered functions                      |
| `.inputrc`         | key bindings                               |
| `.dircolors`       | `ls` colors (Solarized Light, 256-color)   |
| `dedup_history.sh` | one-shot history deduplication script      |
| `deploy.sh`        | deploy script                              |

## Deploy

```
./deploy.sh [-u target_user] [-f extra_file] host1 [host2 ...]
```

- Host `.` — local deploy
- Default target user: `$USER`
- `-f` adds files beyond the default set (repeatable)

```bash
# local + two remote hosts at once
./deploy.sh . host1 host2

# deploy to jenkins account: local + remote
./deploy.sh -u jenkins . host1

# with extras
./deploy.sh -f .bashrc_ -f dedup_history.sh . host1
```

## .bashrc integration

Append `.bashrc_` contents to `.bashrc`, then remove it:

```bash
cat ~/.bashrc_ >> ~/.bashrc && rm ~/.bashrc_
```

`.bash_aliases` is loaded automatically by bash if it exists.

## Hostname aliases

Edit `HOSTNAME_ALIASES` in `.bash_prompt`:

```bash
HOSTNAME_ALIASES=(
    "wawsrvdev175:dev"
)
```

## Key bindings

| Key               | Action                   |
|-------------------|--------------------------|
| Tab / Shift+Tab   | menu-complete (cycling)  |
| Up / Down         | history search by prefix |
| Ctrl+Left / Right | word jump                |
| Home / End        | line start/end           |
| Ins               | overstrike mode          |
| Esc               | clear line               |
| Ctrl+Page Up      | `cd ..`                  |
| Ctrl+Page Down    | interactive `cd`         |
| Page Up           | directory history (`dh`) |
| Page Down         | command history picker   |

## Functions

| Function                                                 | Description                                         |
|----------------------------------------------------------|-----------------------------------------------------|
| `cd`                                                     | interactive subdir picker; logs to `~/.dir_history` |
| `dh`                                                     | directory history browser                           |
| `list`                                                   | file viewer (`less`)                                |
| `rm`                                                     | interactive remove (file or empty dir)              |
| `del`                                                    | forced remove (`rm -rf`)                            |
| `ffind [-sIibH] [-t "pattern"] [dir] "filename_pattern"` | file finder                                         |
| `pshow`                                                  | print `$PATH` line by line                          |
| `calc <expr>`                                            | calculator (`bc -l`)                                |

| Alias              | Description           |
|--------------------|-----------------------|
| `dir`              | `ls -la --color=auto` |
| `cls`              | `clear`               |
| `md`               | `mkdir`               |
| `full`             | `realpath`            |
| `getip`            | current IP address    |
| `..` / `...` / `~` | `cd` shortcuts        |

See `ffind` options in the main README.

## Environment variables

| Variable           | Default | Description                    |
|--------------------|---------|--------------------------------|
| `DIR_HISTORY_SIZE` | 100     | entries in `dh`                |
| `HIST_VIEW_SIZE`   | 200     | entries in PgDn history picker |

## Colors

See color configuration in the main README.

## Windows Terminal

See Windows Terminal configuration in the main README.

## Data files

- `~/.dir_history` — visited directories log (created automatically)
