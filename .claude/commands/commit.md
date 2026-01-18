---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git diff --cached:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(git ls-files:*), Bash(git config:*), Bash(git reset HEAD:*), Bash(git restore --staged:*)
description: Create atomic conventional commits with dynamic analysis and bullet-pointed body
---

# Atomic Conventional Commit Creator

Create git commits following the Conventional Commits specification (https://www.conventionalcommits.org/).

**This command will create as many atomic commits as needed** to properly group related changes together. Each commit should be a self-contained unit that can be understood and reverted independently.

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

1. **Analyze ALL changes** by examining the git context below
2. **Group related changes** into logical atomic commits
3. **For each group**, determine the appropriate commit type and create a commit message
4. **Write clear, concise subjects** in imperative mood (e.g., "add feature" not "added feature")
5. **Create detailed bodies** with bullet points explaining what changed in each commit

## Atomic Commit Principles

When grouping changes into commits, follow these principles:

- **Logical Cohesion**: Each commit should contain changes that are logically related
- **Buildability**: Each commit should leave the codebase in a working state
- **Revertibility**: Each commit should be independently revertible
- **Testability**: Each commit should be testable on its own
- **Size**: Commits should be as small as possible while still being complete

## Grouping Strategy

Group changes by:
1. **Feature/Functionality**: All changes for a single feature
2. **File Type**: Swift files, tests, docs, resources separately
3. **Component/Module**: Changes to different components separately
4. **Intent**: bug fixes separate from new features separate from refactoring
5. **Layer**: Model changes separate from view changes separate from controller changes

**Example grouping:**
- Commit 1: Add new model (feat)
- Commit 2: Add tests for the model (test)
- Commit 3: Update views to use the model (feat)
- Commit 4: Update documentation (docs)

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

Before creating commits, analyze:

- [ ] What files changed? (Swift, tests, resources, docs, configs)
- [ ] What are the logical groupings of these changes?
- [ ] For each group, what is the primary intent?
- [ ] Which commit type best represents each group's intent?
- [ ] What are the specific changes that need to be listed in each commit?
- [ ] Can each commit stand alone and be reverted independently?

## Example Output

For a feature adding authentication (grouped into 3 atomic commits):

**Commit 1:**
```
feat(auth): add OAuth2 authentication flow

- Add OAuth2 authentication with Google provider
- Implement token storage in Keychain
- Create authentication state manager
- Update app delegate to handle auth callbacks

Closes #123
```

**Commit 2:**
```
test(auth): add tests for OAuth2 authentication

- Add unit tests for OAuth2 flow
- Add tests for token storage
- Add tests for authentication state manager
```

**Commit 3:**
```
feat(ui): add login view with social login buttons

- Create LoginViewController with social login buttons
- Add login form validation
- Implement error display for failed authentication
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

1. **Review all git context** above
2. **Analyze ALL changes** and determine logical groupings
3. **Create commit plan** showing all proposed atomic commits with their messages
4. **Ask for user confirmation** on the plan
5. **Execute commits sequentially**:
   - Stage only the files for the current commit
   - Create the commit with `git commit -m "<message>"`
   - Report the commit SHA
   - Move to the next commit
6. **Handle any conflicts** or issues during commit creation

IMPORTANT: Always get explicit confirmation before creating commits. Display the full plan with all commit messages and ask "Create these commits? (y/N):"

## Commit Plan Template

When presenting the plan, use this format:

```
I'll create <N> atomic commits:

Commit 1: <type>(<scope>): <subject>
Files: <list of files>

<full commit message>

---

Commit 2: <type>(<scope>): <subject>
Files: <list of files>

<full commit message>

---

[continue for all commits]
```

## Staging Strategy

When creating multiple commits:
- Use `git add <files>` to stage only files for the current commit
- If files need partial changes, use `git add -p <file>` for interactive staging
- After committing, stage the next group of files
- Continue until all groups are committed
- If any unstaged changes remain, notify the user
