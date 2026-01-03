## Response Format

Use the following structure for every review comment.
Do not deviate unless brevity clearly improves clarity.

1. **State the problem**  
   - One clear sentence describing the concrete issue.
   - Avoid speculation or vague phrasing.

2. **Why it matters** (optional)  
   - One sentence explaining impact (correctness, safety, maintainability, or developer experience).
   - Omit this step if the impact is obvious.

3. **Suggested fix**  
   - Provide a specific action, code snippet, or alternative approach.
   - Prefer minimal, localized changes over broad refactors.

---

### Style Guidelines
- Be direct, neutral, and collaborative.
- Avoid commands; prefer suggestions (“Consider…”, “It may be safer to…”).
- Do not include multiple issues in a single comment.
- Do not restate CI failures or lint output.

---

### Example

This could panic if the vector is empty.  
Consider using `.get(0)` or adding an explicit length check before indexing.
