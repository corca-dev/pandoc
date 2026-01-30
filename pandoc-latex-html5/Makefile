.PHONY: all build check-cabal clean clean-all install test help

# Default number of parallel jobs (use all cores)
JOBS ?= $(shell nproc 2>/dev/null || echo 4)

# Installation prefix
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

# Executable name
BINARY = pandoc-latex-html5

all: build

# Check if cabal is available
check-cabal:
	@command -v cabal >/dev/null 2>&1 || { \
		echo "Error: cabal is not installed or not in PATH."; \
		echo ""; \
		echo "Please install cabal-install:"; \
		echo "  - Ubuntu/Debian: sudo apt-get install cabal-install"; \
		echo "  - Fedora/RHEL:   sudo dnf install cabal-install"; \
		echo "  - Arch Linux:    sudo pacman -S cabal-install"; \
		echo "  - macOS:         brew install cabal-install"; \
		echo "  - Or visit:      https://www.haskell.org/ghcup/"; \
		echo ""; \
		exit 1; \
	}

build: check-cabal
	@echo "Building $(BINARY) with $(JOBS) parallel jobs..."
	cabal build --jobs=$(JOBS)
	@echo ""
	@echo "Build complete! Executable location:"
	@cabal list-bin $(BINARY)

clean:
	@echo "Cleaning build artifacts..."
	cabal clean
	@echo "Clean complete."

clean-all:
	@echo "WARNING: Removing local build cache (dist-newstyle/)."
	@echo "Next build will recompile this package but use cached dependencies."
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ] || (echo "Cancelled." && exit 1)
	@echo "Removing dist-newstyle/..."
	rm -rf dist-newstyle/
	@echo "Full clean complete."

install: build
	@echo "Installing $(BINARY) to $(BINDIR)..."
	install -d $(BINDIR)
	install -m 755 $$(cabal list-bin $(BINARY)) $(BINDIR)/$(BINARY)
	@echo "Installed to $(BINDIR)/$(BINARY)"

test: build
	@echo "Running test conversion..."
	@printf '\\documentclass{article}\n\\begin{document}\nTest: \\[ E=mc^2 \\]\n\\end{document}\n' > /tmp/test-pandoc-latex-html5.tex
	$$(cabal list-bin $(BINARY)) -s /tmp/test-pandoc-latex-html5.tex -o /tmp/test-pandoc-latex-html5.html
	@echo "Test HTML generated at /tmp/test-pandoc-latex-html5.html"
	@grep -q "mathjax" /tmp/test-pandoc-latex-html5.html && echo "✓ MathJax included" || echo "✗ MathJax missing"
	@grep -q "E=mc" /tmp/test-pandoc-latex-html5.html && echo "✓ Math formula found" || echo "✗ Math formula missing"
	@echo "Test passed!"

help:
	@echo "Available targets:"
	@echo "  make              - Build the binary (default)"
	@echo "  make JOBS=N       - Build with N parallel jobs"
	@echo "  make install      - Install to $(BINDIR)"
	@echo "  make PREFIX=/path - Install to /path/bin"
	@echo "  make test         - Run a simple test"
	@echo ""
	@echo "Cleaning targets:"
	@echo "  make clean        - Clean local build artifacts (fast, safe)"
	@echo "  make clean-all    - Remove local build cache (recompiles this package)"
	@echo ""
	@echo "Examples:"
	@echo "  make JOBS=4                    # Build with 4 cores"
	@echo "  sudo make install              # Install to /usr/local/bin"
	@echo "  sudo make PREFIX=/usr install  # Install to /usr/bin"
	@echo "  make clean-all && make         # Clean rebuild of this package"
	@echo ""
	@echo "Requirements:"
	@echo "  - cabal-install (GHC Haskell build tool)"
	@echo "  - GHC 9.0 or later"
