# Project Context for Claude Code

## Environment
- Xcode: 26.0.1 (released September 2025)
- Swift: 6.2
- Testing Framework: Swift Testing (not XCTest)
- iOS Target: iOS 26+

## Testing Standards
- Use Swift Testing framework with `import Testing`
- Use `@Test` macro for test functions
- Use `#expect` for assertions (not XCTAssert)
- All tests with `@Observable` view models require `@MainActor`
- Use `@Suite` for organizing test groups
- Tests should follow Given/When/Then structure with comments

## Project-Specific Rules
- View models MUST use @Observable (Observation). Do NOT use ObservableObject or @Published.
- Prefer SwiftUI state: @State for view-owned state, @Bindable for two-way bindings.
- Avoid importing Combine in UI/state code. No @Published, no ObservableObject.
- Firebase Authentication is the auth backend (mock in tests).
- Follow TDD: write tests first, then implement minimal code to pass.

## AI Coding Guardrails (Authoritative)

These rules are mandatory for any generated code or suggestions:

Do:
- Use modern Observation: `@Observable` for reference models (import Observation in model files).
- Use SwiftUI state: `@State` (owned), `@Environment` (injected), `@Bindable` (two-way binding to @Observable models).
- Prefer Swift Concurrency (async/await) with `@MainActor` for UI-affecting methods.
- Use Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`).

Do NOT:
- Do not use `ObservableObject`.
- Do not use `@Published`.
- Do not import Combine for UI state.
- Do not use XCTest patterns (XCTestCase, XCTAssert, etc.).

When in doubt, choose the most modern SwiftUI + Observation approach available in Xcode 26 / Swift 6.2.

## Prompt Preamble for Claude Code

