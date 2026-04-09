# bash_root

Bash customization for root and service accounts. No `fzf` required.

## Files

| File               | Description                               |
|--------------------|-------------------------------------------|
| `.bashrc_`         | customization block — append to `.bashrc` |
| `.bash_prompt`     | prompt with hostname alias (no git)       |
| `.bash_aliases`    | aliases and small functions               |
| `.bash_functions`  | `ffind`                                   |
| `.inputrc`         | key bindings (subset)                     |
| `.dircolors`       | `ls` colors (Solarized Light, 256-color)  |
| `dedup_history.sh` | one-shot history deduplication script     |
| `deploy_root.sh`   | deploy script                             |

## Deploy

```
./deploy_root.sh [-f extra_file] host1 [host2 ...]
```

- Host `.` — local deploy (via `sudo`)
- Target is always `/root`
- `-f` adds files beyond the default set (repeatable)

```bash
# local + two remote hosts at once
./deploy_root.sh . host1 host2

# with extras
./deploy_root.sh -f .bashrc_ -f dedup_history.sh . host1
```

## .bashrc integration

Append `.bashrc_` contents to `/root/.bashrc`, then remove it:

```bash
sudo sh -c 'cat /root/.bashrc_ >> /root/.bashrc && rm /root/.bashrc_'
```

`.bash_aliases` is loaded automatically by bash if it exists.

## Differences vs bash_user

| Feature                           | bash_user | bash_root |
|-----------------------------------|-----------|-----------|
| Git in prompt                     | yes       | no        |
| fzf (cd, dh, list, rm, del, hist) | yes       | no        |
| `ffind`                           | yes       | yes       |
| PgDn (command history)            | yes       | no        |
| Ctrl+PgDn (interactive cd)        | yes       | no        |
| PgUp (directory history)          | yes       | no        |
| Ctrl+PgUp (cd ..)                 | yes       | yes       |

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

## Functions and aliases

| Function / Alias                                         | Description                |
|----------------------------------------------------------|----------------------------|
| `ffind [-sIibH] [-t "pattern"] [dir] "filename_pattern"` | file finder                |
| `pshow`                                                  | print `$PATH` line by line |
| `calc <expr>`                                            | calculator (`bc -l`)       |
| `dir`                                                    | `ls -la --color=auto`      |
| `cls`                                                    | `clear`                    |
| `md`                                                     | `mkdir`                    |
| `full`                                                   | `realpath`                 |
| `getip`                                                  | current IP address         |
| `..` / `...` / `~`                                       | `cd` shortcuts             |

See `ffind` options in the main README.

## Colors

See color configuration in the main README.

## Windows Terminal

See Windows Terminal configuration in the main README.

