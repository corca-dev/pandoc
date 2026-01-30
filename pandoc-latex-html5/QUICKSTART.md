# Quick Start

## Build

```bash
make              # Use all cores
make JOBS=4       # Use 4 cores
```

## Install

```bash
sudo make install                    # Install to /usr/local/bin
sudo make PREFIX=/usr install        # Install to /usr/bin
```

## Use

```bash
pandoc-latex-html5 input.tex                      # Fragment to stdout
pandoc-latex-html5 -s input.tex -o output.html    # Standalone file
```

## Docker

```bash
# Build image
docker build -t latex2html .

# Convert file
docker run --rm -v $(pwd):/work -w /work latex2html input.tex -s -o output.html
```
