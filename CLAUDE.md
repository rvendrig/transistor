# CLAUDE.md - AI Assistant Development Guide

This document provides guidance for Claude and other AI assistants working on the **transistor** repository. It outlines the codebase structure, development workflows, and key conventions to follow.

---

## Overview

**transistor** is a [PROJECT_DESCRIPTION_TO_BE_FILLED]. This is a fresh repository where AI-assisted development can help bootstrap the initial project structure and implementation.

### Key Information
- **Repository**: rvendrig/transistor
- **Primary Branch**: main (or as specified per feature)
- **Development Branches**: Feature branches follow the pattern `claude/[feature-description]-[suffix]`
- **Repository Type**: [To be determined during development]

---

## Repository Structure

As this is a new repository, the structure will be built incrementally. Here's the recommended structure for most projects:

```
transistor/
├── CLAUDE.md                    # This file - AI assistant guidelines
├── README.md                    # Project overview and setup instructions
├── package.json                 # Dependencies and scripts (if Node/JS)
├── .gitignore                   # Git ignore rules
├── .github/
│   └── workflows/               # CI/CD pipelines
├── src/                         # Source code
│   └── [module structure]
├── tests/                       # Test files
├── docs/                        # Project documentation
└── [config files]               # ESLint, prettier, tsconfig, etc.
```

**Note**: Adjust this structure based on the project's actual needs once the technology stack is decided.

---

## Technology Stack

To be determined during initial project setup. Common stacks:
- **JavaScript/TypeScript**: Node.js, React, Express, etc.
- **Python**: Flask, Django, FastAPI, etc.
- **Go**, **Rust**, or other languages
- **Full-stack**: Frontend + Backend combination

Update this section once the tech stack is chosen and initialized.

---

## Development Workflow

### For AI Assistants

When working on this repository, follow these practices:

#### 1. **Before Starting**
- Check if a CLAUDE.md exists and understand the current project state
- Read any existing documentation (README, docs/)
- Understand the git branch you're working on (usually `claude/[feature]`)
- Verify git is configured properly

#### 2. **Understanding the Codebase**
- Use the Glob tool for fast file pattern searches (e.g., "src/**/*.ts")
- Use the Grep tool for content-based searches (e.g., "function name", "import X")
- Use the Read tool to examine specific files in detail
- Don't make assumptions about code structure - read first, then modify

#### 3. **Making Changes**
- **Read Before Edit**: Always read a file before modifying it with the Edit tool
- **Prefer Edit Over Write**: Use Edit for modifications, Write only for new files
- **Atomic Commits**: Make logical, focused commits with clear messages
- **Test Changes**: Run tests after modifications to ensure nothing breaks
- **Type Safety**: Use type annotations where the language supports them (TypeScript, Python with type hints)
- **Security First**: Watch for injection vulnerabilities (XSS, SQL injection, command injection)

#### 4. **Code Quality**
- Follow existing code style and conventions
- Don't over-engineer: solve the problem at hand, not hypothetical future needs
- Don't add unnecessary abstraction layers or helper functions for one-time use
- Add comments only where logic isn't self-evident
- Avoid backwards-compatibility hacks for unused code - delete cleanly instead

#### 5. **Git Practices**
- **Feature Branches**: Work on assigned feature branches (e.g., `claude/add-feature-XXX`)
- **Commit Hygiene**:
  ```bash
  # Good commit message format:
  # - Clear, descriptive subject line (max 70 chars)
  # - Leave blank line
  # - Detailed explanation if needed
  # - Include the Claude Code session URL for tracking
  ```
- **Never Force Push**: Unless explicitly authorized, avoid `git push --force`
- **Push Strategy**: Use `git push -u origin <branch-name>` for new branches
- **Branch Naming**: Follow pattern: `<prefix>/<description>-<suffix>` (e.g., `claude/fix-auth-abc123`)

#### 6. **Testing**
- Run all tests before committing: `npm test`, `pytest`, etc.
- Verify new functionality with manual testing where UI is involved
- Fix test failures immediately - don't commit broken tests
- Aim for comprehensive coverage of critical paths

#### 7. **Documentation**
- Update README when adding major features
- Document complex algorithms or non-obvious decisions
- Keep CLAUDE.md updated as the project evolves
- Include inline comments for tricky logic

---

## Key Conventions

### Code Style
- **Indentation**: [2 or 4 spaces - to be decided]
- **Line Length**: 100-120 characters preferred
- **Naming**:
  - camelCase for variables and functions in JavaScript/TypeScript
  - snake_case for variables and functions in Python
  - PascalCase for classes and components
  - UPPER_SNAKE_CASE for constants

### File Organization
- One main export per file (unless utilities file)
- Group related functionality together
- Keep files under 300-400 lines when practical
- Use index files to re-export from directories when needed

### Error Handling
- Validate input at system boundaries (user input, external APIs)
- Trust internal APIs and framework guarantees
- Use typed errors/exceptions
- Provide meaningful error messages

### Dependencies
- Keep dependency count minimal
- Use stable, well-maintained packages
- Document why each dependency is needed
- Review license compatibility

---

## Common Tasks

### Setting Up for Development

1. **Clone the repository** (if not done):
   ```bash
   git clone <repo-url>
   cd transistor
   ```

2. **Create/Switch to development branch**:
   ```bash
   git checkout -b claude/feature-description-suffix
   # or switch to existing branch
   git checkout claude/existing-feature
   ```

3. **Install dependencies** (once structure is defined):
   ```bash
   npm install      # for JavaScript/Node
   # or
   pip install -r requirements.txt  # for Python
   ```

4. **Start development**:
   - Make changes following the conventions above
   - Test frequently
   - Commit with clear messages

5. **Push changes**:
   ```bash
   git push -u origin claude/feature-description-suffix
   ```

### Running Tests
- **JavaScript**: `npm test` or `yarn test`
- **Python**: `pytest` or `python -m unittest`
- Always run tests before committing

### Building/Packaging
- Document build commands once the project structure is set up
- Include build artifacts in .gitignore
- Keep build configuration version-controlled

### Debugging
- Use IDE debugging when available
- Add console/print statements strategically
- Check logs and error messages carefully
- Verify assumptions with test cases

---

## Anti-Patterns to Avoid

❌ **Don't:**
- Guess URLs or make up tool parameters
- Commit without reading existing code first
- Add unnecessary comments or type annotations
- Create helper functions for one-time operations
- Use force push to shared branches
- Skip hooks or security checks
- Add unused imports or dead code
- Create overly complex abstractions upfront

✅ **Do:**
- Read the codebase thoroughly before making changes
- Make focused, logical commits
- Test your changes
- Follow existing patterns and style
- Keep changes minimal and focused
- Use appropriate tools for the task (Read vs Grep vs Glob)
- Ensure security throughout development

---

## Updating This Guide

This CLAUDE.md should evolve as the project develops:

1. **Add technology-specific details** once the stack is chosen
2. **Document project-specific workflows** as they emerge
3. **Update directory structure** with actual organization
4. **Add tool/command instructions** specific to the project
5. **Include deployment procedures** once applicable
6. **Document known issues or gotchas** as they're discovered

---

## Questions or Issues?

For questions about Claude Code usage, features, or hooks:
- See `/help` in Claude Code for built-in help
- Report issues at: https://github.com/anthropics/claude-code/issues

For repository-specific questions:
- Refer to this CLAUDE.md first
- Check existing documentation and code
- Ask in pull request discussions

---

**Last Updated**: 2026-04-12  
**Version**: 1.0 (Initial template for empty repository)
