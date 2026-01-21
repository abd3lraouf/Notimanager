# Contributing to Notimanager

Guidelines for contributing to the project.

## Code of Conduct

- Be respectful and constructive
- Welcome new contributors and help them learn
- Focus on what is best for the community
- Show empathy toward other community members

## How to Contribute

### Reporting Bugs

Check existing issues first. When creating a bug report, include:

- **Title**: Clear and descriptive
- **Description**: Detailed explanation of the problem
- **Steps to reproduce**: Numbered steps to reproduce
- **Expected behavior**: What you expected to happen
- **Actual behavior**: What actually happened
- **Environment**: macOS version, Notimanager version
- **Screenshots/logs**: If applicable

### Suggesting Enhancements

- Use a clear, descriptive title
- Provide a detailed description
- Explain why the enhancement would be useful
- List examples or use cases

### Pull Requests

1. Fork and create a branch from `main`
2. Make changes with clear commit messages
3. Write tests for new features or bug fixes
4. Ensure all tests pass
5. Update documentation if needed
6. Submit a pull request with a clear description

## Development Setup

```bash
git clone https://github.com/abd3lraouf/Notimanager.git
cd Notimanager
open Notimanager.xcodeproj
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for details.

## Coding Standards

### Swift Style

- Follow standard Swift naming conventions
- Use meaningful variable and function names
- Prefer `let` over `var` when possible
- Use `guard` statements for early returns
- Mark `private` and `fileprivate` appropriately
- Group related code using `// MARK: -` comments

### Example MARK usage

```swift
// MARK: - Properties
private var observers: [NSObjectProtocol]?

// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
}

// MARK: - Actions
@objc private func buttonTapped() {
    // ...
}

// MARK: - Private Methods
private func setupUI() {
    // ...
}
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

**Examples**:
```
feat(settings): add dark mode toggle
fix(crash): resolve window positioning on macOS 14
docs(readme): update installation instructions
refactor(manager): simplify notification detection logic
```

## Testing

```bash
./scripts/build.sh test
```

- Write unit tests for business logic
- Write UI tests for user interactions
- Mock external dependencies
- Test edge cases and error conditions

## Documentation

- Update relevant documentation files
- Keep descriptions clear and concise
- Include code examples where helpful
- Update [CHANGELOG.md](CHANGELOG.md) for user-facing changes

## Release Process

1. Update [CHANGELOG.md](CHANGELOG.md) with release notes
2. Run `./scripts/build.sh prepare` and enter version number
3. Push to GitHub:
   ```bash
   git push origin main
   git push origin v1.0.0
   ```

See [DEVELOPMENT.md](DEVELOPMENT.md) for details.

## Questions?

- Check [GitHub Issues](https://github.com/abd3lraouf/Notimanager/issues)
- Create a new issue for questions or problems
- Read the [documentation](README.md)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
