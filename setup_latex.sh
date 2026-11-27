#!/usr/bin/env bash
# Install a local LaTeX toolchain (pdfLaTeX + BibTeX) with every package the TDP uses,
# then check that each package is found.
#
#   ./setup_latex.sh            # install (asks for sudo) and check
#   ./setup_latex.sh --check    # only check what is installed
set -euo pipefail

# Debian/Ubuntu packages -> LaTeX packages they provide (checked on Ubuntu 24.04)
APT_PACKAGES=(
  texlive-binaries            # pdflatex, bibtex, kpsewhich
  texlive-base                # amssymb, ifxetex
  texlive-latex-base          # amsmath, babel, fancyhdr, fontenc, geometry, graphicx, hyperref,
                              # inputenc, tabularx, url, varioref
  texlive-latex-recommended   # booktabs, float, xcolor
  texlive-latex-extra         # cleveref, csquotes, enumitem, lastpage, nowidow, standalone,
                              # titling, wrapfig
  texlive-fonts-recommended   # wasysym
  texlive-pictures            # tikz / pgf
  lmodern                     # Latin Modern fonts
)

# LaTeX packages used by tdp/main.tex and tdp/figures/*.tex (llncs.cls ships in tdp/)
STY=(amsmath amssymb babel booktabs cleveref csquotes enumitem fancyhdr float fontenc geometry
     graphicx hyperref ifxetex inputenc lastpage lmodern nowidow tabularx tikz titling url
     varioref wasysym wrapfig xcolor)
CLS=(standalone)

check() {
  local missing=0
  for bin in pdflatex bibtex kpsewhich; do
    if ! command -v "$bin" >/dev/null; then echo "missing program: $bin"; missing=1; fi
  done
  if command -v kpsewhich >/dev/null; then
    for p in "${STY[@]}"; do
      [[ -n "$(kpsewhich "$p.sty")" ]] || { echo "missing LaTeX package: $p"; missing=1; }
    done
    for c in "${CLS[@]}"; do
      [[ -n "$(kpsewhich "$c.cls")" ]] || { echo "missing LaTeX class: $c"; missing=1; }
    done
    [[ -n "$(kpsewhich english.ldf)$(kpsewhich english.sty)" ]] || { echo "missing babel language: english"; missing=1; }
  fi
  if (( missing )); then echo "LaTeX setup incomplete"; return 1; fi
  echo "LaTeX setup OK: $(pdflatex --version | head -1)"
}

if [[ "${1:-}" == "--check" ]]; then
  check
  exit $?
fi

if command -v apt-get >/dev/null; then
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"
elif command -v dnf >/dev/null; then
  sudo dnf install -y texlive-scheme-basic texlive-collection-latexrecommended \
    texlive-collection-latexextra texlive-collection-pictures texlive-collection-fontsrecommended \
    texlive-lm texlive-bibtex
elif command -v pacman >/dev/null; then
  sudo pacman -S --needed texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra \
    texlive-pictures texlive-fontsrecommended texlive-binextra
elif command -v brew >/dev/null; then
  brew install --cask mactex-no-gui
  echo "Open a new terminal so /Library/TeX/texbin is on PATH, then rerun with --check."
  exit 0
else
  echo "No supported package manager found. Install TeX Live (https://tug.org/texlive/) with"
  echo "the packages: ${STY[*]} ${CLS[*]}"
  exit 1
fi

check
