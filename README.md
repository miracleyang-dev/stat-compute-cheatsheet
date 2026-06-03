# stat-compute-cheatsheet

Offline-ready statistical computing exam cheatsheet with R code solutions.

## Overview

An interactive, single-page HTML reference covering 7 chapters of a statistical computing course. Designed for open-book exams — works entirely offline with no internet required.

### Topics

| Chapter | Topic | Problems |
|---------|-------|----------|
| Ch1 | R Basics & Data I/O | 6 |
| Ch2 | Random Variable Generation | 6 |
| Ch3 | Monte Carlo Integration | 4 |
| Ch4 | MC Inference (CI & Hypothesis Testing) | 4 |
| Ch5 | Bootstrap & Jackknife | 3 |
| Ch6 | Numerical Optimization | 3 |
| Ch7 | MCMC (Metropolis-Hastings) | 3 |

### Features

- Collapsible chapters and problems for quick navigation
- Complete R code for every homework problem
- LaTeX-rendered formulas via bundled KaTeX (offline)
- Print-friendly layout (auto-expands all sections)

## Usage

```
git clone https://github.com/miracleyang-dev/stat-compute-cheatsheet.git
```

Open `index.html` in any browser. No server or internet required.

## Structure

```
.
├── index.html          # Main cheatsheet (self-contained)
└── katex/              # Bundled KaTeX for offline math rendering
    ├── katex.min.css
    ├── katex.min.js
    ├── auto-render.min.js
    └── fonts/
```

## License

[MIT](LICENSE)
