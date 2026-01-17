---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git diff --cached:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(git ls-files:*), Bash(git config:*)
description: Create a conventional commit with dynamic analysis and bullet-pointed body
---

# Conventional Commit Creator

Create a git commit following the Conventional Commits specification (https://www.conventionalcommits.org/).

## Available Commit Types

Choose the most appropriate type:
- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect code meaning (formatting, etc.)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

## Your Task

1. **Analyze the changes** by examining the git context below
2. **Determine the appropriate commit type** based on what changed
3. **Write a clear, concise subject** in imperative mood (e.g., "add feature" not "added feature")
4. **Create a detailed body** with bullet points explaining what changed

## Git Context

### Current Status
!`git status --short`

### Staged Changes
!`git diff --cached --stat`

### Unstaged Changes
!`git diff --stat`

### Untracked Files
!`git ls-files --others --exclude-standard`

### Recent Commits (for style reference)
!`git log --oneline -5`

### Current Branch
!`git branch --show-current`

## Commit Format

Follow this structure:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Guidelines

1. **Subject line**:
   - Use imperative mood ("add" not "added" or "adds")
   - Keep it under 72 characters total
   - Do not end with a period
   - Reference specific files/components when relevant

2. **Scope** (optional):
   - Use parentheses after the type: `type(scope): description`
   - Examples: `feat(auth):`, `fix(ui):`, `refactor(database):`
   - Scope should be the module/component affected

3. **Body** (REQUIRED for non-trivial changes):
   - Explain **what** and **why** (not **how**)
   - Use bullet points for multiple items
   - Each bullet should be a specific change
   - Wrap at 72 characters per line
   - Start with "Why this change?" paragraph if needed

4. **Breaking Changes** (if applicable):
   - Add a footer starting with `BREAKING CHANGE: `
   - Describe the breaking change and migration path

5. **References** (optional):
   - `Closes #issue` or `Fixes #issue`
   - `Refs #issue`

## Analysis Checklist

Before creating the commit, analyze:

- [ ] What files changed? (Swift, tests, resources, docs, configs)
- [ ] What is the primary intent of these changes?
- [ ] Which commit type best represents this intent?
- [ ] Is there a clear scope/module affected?
- [ ] What are the specific changes that need to be listed?

## Example Output

For a feature adding authentication:
```
feat(auth): add OAuth2 login support

- Add OAuth2 authentication flow with Google provider
- Implement token storage in Keychain
- Create LoginViewController with social login buttons
- Add authentication state manager
- Update app delegate to handle auth callbacks

Closes #123
```

For a bug fix:
```
fix(notification): prevent duplicate notifications

- Add deduplication logic to notification manager
- Fix notification ID collision issue
- Add unique identifier based on timestamp and content

Fixes #456
```

For a refactor:
```
refactor(coordinator): extract common navigation logic

- Move shared navigation patterns to BaseCoordinator
- Simplify child coordinator initialization
- Remove duplicate route handling code
```

## Execution Steps

1. Review all git context above
2. Analyze changes to determine type, scope, and content
3. If no files are staged, ask user if they want to stage all changes
4. Present the proposed commit message clearly formatted
5. Ask for user confirmation
6. If confirmed, stage any unstaged changes that are part of this commit, then create the commit with `git commit -m "<message>"`
7. Report the commit SHA and success message

IMPORTANT: Always get explicit confirmation before creating the commit. Display the full commit message and ask "Create this commit? (y/N):"
