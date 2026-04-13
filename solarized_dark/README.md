# Solarized Dark (fixed)

Drop-in replacement `.dircolors` + Windows Terminal color scheme for Solarized Dark (fixed).

The prompt (`.bash_prompt`) uses ANSI 16-color codes — it adapts automatically
to the terminal palette, no changes needed there.

## Usage

```bash
cp .dircolors ~/.dircolors
```

## Changes vs Solarized Light `.dircolors`

| Element              | Light | Dark  | Reason                              |
|----------------------|-------|-------|-------------------------------------|
| archives             | 61    | 105   | 61 (#5f5faf) too dark on #002B36    |
| compiled / logs      | 240   | 244   | 240 (#585858) nearly invisible      |
| special file bg      | 230   | 235   | cream bg blindingly bright on dark  |

All other values unchanged — they have sufficient contrast on both backgrounds.

## Windows Terminal

Settings: `Ctrl+,` → **Color schemes** → Add, or edit `settings.json`.

Profile:

```json
"font": {
    "face": "JetBrains Mono",
    "size": 12
},
"colorScheme": "Solarized Dark (fixed)"
```

Color scheme:

```json
{
  "name": "Solarized Dark (fixed)",
  "background": "#002B36",
  "foreground": "#839496",
  "cursorColor": "#839496",
  "selectionBackground": "#073642",
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
> `.dircolors` uses 256-color — unaffected by palette.
