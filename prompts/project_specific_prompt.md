## Project-Specific Context

- This is a **Rust project organized as a Cargo workspace**.  
  - Be aware of crate boundaries, shared dependencies, and cross-crate public APIs.
  - Prefer changes that preserve workspace consistency over isolated optimizations.

- Core crates in this repository:
  - `goose`
  - `goose-cli`
  - `goose-server`
  - `goose-mcp`
  Review changes with awareness of each crate’s role and responsibility.

- **Error handling**
  - Use `anyhow::Result` for fallible operations in production code.
  - Avoid `unwrap()` and `expect()` outside of tests, benchmarks, or clearly documented invariants.
  - When adding context, ensure it meaningfully improves debuggability.

- **Async runtime**
  - The project uses **Tokio**.
  - Avoid blocking operations (`std::fs`, `std::thread::sleep`, heavy CPU work) in async contexts.
  - Prefer async-native libraries and patterns compatible with Tokio.

- **AI-assisted code standards**
  - Follow guidance defined in `HOWTOAI.md`.
  - Ensure AI-generated changes are **intentional, minimal, and aligned with existing patterns**.
  - Flag code that appears auto-generated but does not integrate cleanly with the surrounding codebase.

- **MCP protocol implementations**
  - Treat MCP-related code as **high-sensitivity and high-impact**.
  - Apply extra scrutiny to correctness, validation, error handling, and protocol compliance.
  - Prefer explicitness and clarity over cleverness in protocol logic.
