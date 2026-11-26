# EIC Chula — RoboCup@Home 2027 Team Description Paper

Team Description Paper (TDP) for RoboCup@Home 2027, written in the Springer LNCS format
(`llncs.cls`). It is based on the [RoboCup@Home TDP template](https://github.com/RoboCupAtHome/TDPTemplate).
Limit: 8 pages including references, plus the robot specification sheet (OPL annex) at the end.

## Layout

```
.
├── build.sh               # build a paper: pdflatex -> bibtex -> pdflatex x2
├── setup_latex.sh         # install / check the local TeX Live toolchain
├── extra_dict.pws         # extra words for the spell checker (aspell)
└── tdp/
    ├── main.tex           # the paper (main.pdf is written next to it)
    ├── RobotDescriptionOPL.tex   # robot specification sheet annex
    ├── macros.tex
    ├── citations.bib      # BibTeX references
    ├── llncs.cls, unsrt.bst      # Springer class and bibliography style (kept local)
    ├── figures/           # TikZ diagrams (\input) + standalone preview-*.tex
    ├── images/            # photos and screenshots
    └── build/             # aux/log/bbl files (git-ignored)
```

## 1. Install the LaTeX toolchain

The paper builds with **pdfLaTeX + BibTeX** from TeX Live. You don't need `texlive-full`.
`setup_latex.sh` installs the TeX Live packages the paper needs and then checks that every
LaTeX package is found:

```bash
./setup_latex.sh            # install (asks for sudo), then check
./setup_latex.sh --check    # only check what is already installed
```

On Ubuntu/Debian it installs:

| apt package                 | provides                                                              |
|-----------------------------|-----------------------------------------------------------------------|
| `texlive-binaries`          | `pdflatex`, `bibtex`, `kpsewhich`                                     |
| `texlive-base`              | amssymb, ifxetex                                                      |
| `texlive-latex-base`        | amsmath, babel, fancyhdr, fontenc, geometry, graphicx, hyperref, inputenc, tabularx, url, varioref |
| `texlive-latex-recommended` | booktabs, float, xcolor                                               |
| `texlive-latex-extra`       | cleveref, csquotes, enumitem, lastpage, nowidow, standalone, titling, wrapfig |
| `texlive-fonts-recommended` | wasysym                                                               |
| `texlive-pictures`          | TikZ / PGF                                                            |
| `lmodern`                   | Latin Modern fonts (vector T1 fonts)                                  |

The script also has install commands for Fedora (`dnf`), Arch (`pacman`) and macOS (`brew`).

If you add a `\usepackage{...}` to the paper, also add it to `STY` in `setup_latex.sh` so
`--check` keeps covering it.

## 2. Build the paper

```bash
./build.sh tdp/main.tex     # one paper
./build.sh --all            # every */main.tex in the repo
```

This runs pdfLaTeX, then BibTeX (only if the `.tex` uses `\bibliography`), then pdfLaTeX twice.
`tdp/main.pdf` is written next to the source, and the intermediate files go to `tdp/build/`.
If the build fails, the script prints the first LaTeX errors and the path to the full log.
Undefined citations or references and missing files are printed at the end.

## 3. (Optional) The `ltx` shell shortcut

`build.sh` is the same build as the `ltx` function from my `~/.zshrc`. To compile any `.tex` file
from anywhere with `ltx path/to/file.tex`, add this to `~/.zshrc` and run `source ~/.zshrc`:

```zsh
# ltx <path/to/file.tex>  -> PDF next to the .tex, aux/log files in <folder>/build/
# Images are resolved via \graphicspath in the .tex; runs bibtex if \bibliography is used.
ltx() {
  if [[ $# -ne 1 ]]; then echo "usage: ltx <path/to/file.tex>"; return 1; fi
  local dir=${${1:h}:A} name=${${1:t}%.tex}
  [[ -f "$dir/$name.tex" ]] || { echo "ltx: $dir/$name.tex not found"; return 1; }
  mkdir -p "$dir/build" || return 1
  _ltx_pass() {
    ( cd "$dir" && pdflatex -interaction=nonstopmode -halt-on-error \
        -output-directory=build "$name.tex" > /dev/null ) \
      || { echo "ltx: error, see $dir/build/$name.log"; grep -m5 -A3 '^!' "$dir/build/$name.log"; return 1; }
  }
  _ltx_pass || return 1
  if grep -q '^[^%]*\\bibliography{' "$dir/$name.tex"; then
    ( cd "$dir" && BIBINPUTS="$dir:" bibtex "build/$name" > "build/$name.bibtex.out" ) \
      || { echo "ltx: bibtex error, see $dir/build/$name.blg"; grep -m5 -i 'error\|warning' "$dir/build/$name.blg"; return 1; }
  fi
  _ltx_pass && _ltx_pass || return 1
  grep -m5 'LaTeX Warning: \(Citation\|Reference\|File\)' "$dir/build/$name.log"
  mv -f "$dir/build/$name.pdf" "$dir/$name.pdf" && echo "ltx: wrote $dir/$name.pdf"
}
```

Then:

```bash
ltx tdp/main.tex
```

## Figure previews

Each TikZ diagram in `tdp/figures/` has a `preview-<name>.tex` that renders it alone, which is
quicker when you're working on one diagram:

```bash
./build.sh tdp/figures/preview-arch-evolution.tex   # -> tdp/figures/preview-arch-evolution.pdf
```

## Licence

The template files are under the MIT licence. See [LICENCE.md](LICENCE.md).
