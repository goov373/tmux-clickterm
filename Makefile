# clickterm Makefile
# Development automation for clickterm

SHELL := /bin/bash
.PHONY: all install reload dev lint test clean hooks help

# Default target
all: help

# Installation
install:
	@./install.sh

# Reload tmux configuration
reload:
	@if [ -n "$$TMUX" ]; then \
		tmux source-file ~/.tmux.conf; \
		echo "tmux configuration reloaded."; \
	else \
		echo "Not in tmux session. Start tmux to see changes."; \
	fi

# Development: install + reload
dev: install reload
	@echo "Development cycle complete."

# Lint all shell scripts
lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x *.sh && echo "All scripts passed!"; \
	else \
		echo "shellcheck not installed. Install with: brew install shellcheck"; \
		exit 1; \
	fi

# Test configuration validity
test:
	@echo "Testing tmux configuration..."
	@tmux -f configs/tmux.conf start-server \; kill-server 2>/dev/null && echo "tmux config: OK" || echo "tmux config: FAILED"
	@echo "Testing JSON files..."
	@for f in *.json configs/**/*.json; do \
		if [ -f "$$f" ]; then \
			python3 -m json.tool "$$f" >/dev/null 2>&1 && echo "$$f: OK" || echo "$$f: FAILED"; \
		fi \
	done

# Clean installed files
clean:
	@echo "Removing installed clickterm files..."
	@rm -rf ~/.config/clickterm
	@echo "Note: ~/.tmux.conf was not removed. Remove manually if needed."
	@echo "Done."

# Setup git hooks
hooks:
	@echo "Setting up git hooks..."
	@git config core.hooksPath .githooks
	@echo "Git hooks enabled. Pre-commit will run shellcheck."

# Help
help:
	@echo "clickterm Development Commands"
	@echo ""
	@echo "  make install      Install clickterm to ~/.config/clickterm"
	@echo "  make reload       Reload tmux configuration"
	@echo "  make dev          Install + reload (development cycle)"
	@echo "  make lint         Run shellcheck on all scripts"
	@echo "  make test         Validate config files"
	@echo "  make hooks        Enable git pre-commit hooks"
	@echo "  make clean        Remove installed files"
	@echo "  make help         Show this help"
