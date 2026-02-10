# pandoc-latex-html5

Minimal LaTeX → HTML5 converter with MathJax support.

A stripped-down version of Pandoc that only converts LaTeX files to HTML5, 
optimized for fast compilation times.

## Features

- LaTeX input → HTML5 output only
- MathJax 3 for math rendering
- Standalone HTML documents or fragments
- ~60-70% faster compilation than full Pandoc
- **raw_tex extension enabled** - preserves tikzpicture and other raw LaTeX environments
- **Lua filter support** - compatible with pandoc Lua filters (e.g., for TikZ → SVG conversion)
- **Uses patched Pandoc** from parent directory with improved LaTeX environment handling

## Building

**Important:** This project uses the **patched Pandoc source** from the parent directory 
(`../`), not the public version from Hackage. The patch adds better handling for 
unsupported inline LaTeX environments.

### Prerequisites

- GHC (Haskell compiler) 9.6 or later
- Cabal 3.0 or later

### Quick Build

```bash
make
```

This will build the optimized binary. First build takes 5-10 minutes, 
subsequent builds take 1-2 minutes.

### Build with specific CPU cores

```bash
make JOBS=4      # Use 4 cores
make JOBS=1      # Single-threaded
```

### Install

```bash
sudo make install
```

Installs to `/usr/local/bin/pandoc-latex-html5`

**Note for Lua filters**: If using Lua filters, you may need to install pandoc's data files:

```bash
# Copy data files from the pandoc source
mkdir -p ~/.cabal/share/x86_64-linux-ghc-9.6.7/pandoc-3.8.3/
cp -r ../data ~/.cabal/share/x86_64-linux-ghc-9.6.7/pandoc-3.8.3/
```

Or install the full pandoc package which includes these files.

### Other commands

```bash
make clean       # Clean build artifacts
make test        # Run a simple test
```

## Usage

```bash
# HTML fragment (stdout)
pandoc-latex-html5 input.tex

# Standalone HTML document
pandoc-latex-html5 -s input.tex -o output.html

# With Lua filter (e.g., convert TikZ to SVG)
pandoc-latex-html5 --lua-filter tikz.lua -s input.tex -o output.html

# Multiple filters can be chained
pandoc-latex-html5 --lua-filter filter1.lua --lua-filter filter2.lua input.tex

# Help
pandoc-latex-html5 --help
```

### TikZ to SVG Conversion

The tool supports converting TikZ diagrams to SVG using a Lua filter. You'll need:
- `pdflatex` (from TeX Live or similar)
- `pdf2svg` (SVG conversion tool)
- A Lua filter (see [pandoc's lua-filters documentation](https://pandoc.org/lua-filters.html))

Example filter available in pandoc source: `doc/lua-filters.md` (search for "tikz")

## Docker

See `Dockerfile.example` for a complete example.

```dockerfile
FROM haskell:9.6-slim

WORKDIR /build
COPY . .

# Build and install (uses all available cores)
RUN make && make install

# Binary now at /usr/local/bin/pandoc-latex-html5
```

Build and use:
```bash
docker build -t pandoc-latex-html5 .
docker run --rm -v $(pwd):/work -w /work pandoc-latex-html5 input.tex -s -o output.html
```
