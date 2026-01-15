
```markdown
# Migrating to pnpm for Next.js Projects

This guide provides clear, concise procedures for migrating existing Next.js applications to `pnpm`, as well as setting up new projects with the package manager. As a Next.js developer, I prioritize speed, disk efficiency, and strict dependency management—all of which `pnpm` excels at.

---

## 1. Installation and Global Configuration

### Installing pnpm
It is recommended to use the standalone script to install `pnpm` via npm, or use the standalone installer.

**Via npm (easiest for existing Node users):**
```bash
npm install -g pnpm
```

**Via Standalone Script (POSIX systems):**
```bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

### Enabling Strict Peer Dependencies (Recommended)
Next.js often relies on strict peer dependency resolution. It is best practice to enforce this in your global or project-specific configuration to avoid runtime errors.

**Global Config:**
```bash
pnpm config set strict-peer-dependencies=true
```

---

## 2. Migrating Existing Projects

This process assumes you are currently using `npm` or `yarn`.

### Step 1: Clean Up Existing Artifacts
Before installing, you must remove the existing dependency tree and lockfiles to prevent conflicts.

Run these commands in your project root:

```bash
# Remove the node_modules directory
rm -rf node_modules

# Remove existing lockfiles (package-lock.json or yarn.lock)
rm -f package-lock.json yarn.lock
```

### Step 2: Install Dependencies
Generate the `pnpm-lock.yaml` and populate the `node_modules` directory using `pnpm`.

```bash
pnpm install
```

> **Note:** If you encounter errors regarding peer dependencies (common in older Next.js versions or complex monorepos), you can temporarily bypass the strict check with the flag:
> `pnpm install --shamefully-hoist` (Use sparingly).

### Step 3: Configuration (.npmrc)
While not always required, it is good practice to add an `.npmrc` file at the root of your project to explicitly set pnpm behaviors for your team.

Create `.npmrc`:
```ini
shamefully-hoist=false
strict-peer-dependencies=true
```

---

## 3. Modifying Scripts and `package.json`

### Do Scripts Change?
**Code inside scripts generally remains the same.** You do not need to change the command strings inside the `scripts` object of `package.json`.

**Example `package.json` (No changes needed to content):**
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest"
  }
}
```

### How to Run Scripts
The change is in **how you invoke** these scripts in your terminal.

| Old Command | New Command |
| :--- | :--- |
| `npm run dev` | `pnpm dev` |
| `npm run build` | `pnpm build` |
| `npm install` | `pnpm install` |
| `npm install <package>` | `pnpm add <package>` |
| `npm install -D <package>` | `pnpm add -D <package>` |

### Important: Handling `npx` in Scripts
If you have scripts that utilize `npx` directly, you should replace them with `pnpm exec`.

*   **Before:** `"generate": "npx prisma generate"`
*   **After:** `"generate": "pnpm prisma generate"`

---

## 4. Testing the Migration

After installation, verify that the build, test, and development servers function correctly.

1.  **Development Server:**
    ```bash
    pnpm dev
    ```
    *Check:* Verify the browser loads at `http://localhost:3000`.

2.  **Production Build:**
    ```bash
    pnpm build
    ```
    *Check:* Ensure the build completes without errors regarding missing modules (e.g., "Module not found: Can't resolve 'xyz'").

3.  **Running Tests:**
    ```bash
    pnpm test
    ```
    *Check:* Ensure all unit and integration tests pass.

---

## 5. Starting a New Project with pnpm

If you are starting a fresh Next.js 16 (or latest) project, you can scaffold it specifically for pnpm.

**Using `create-next-app`:**
This command automatically initializes `pnpm`, creates the `pnpm-lock.yaml`, and configures the project.

```bash
npx create-next-app@latest my-next-app --use-pnpm
```

You will be walked through the standard configuration prompts (TypeScript, ESLint, Tailwind, etc.).

**Manual Initialization:**
If you prefer to set up the folder structure yourself:

```bash
mkdir my-next-app
cd my-next-app
pnpm init
pnpm add next@latest react react-dom
```

Then manually update `package.json` scripts as shown in Section 3.

---

## 6. Troubleshooting Common Issues

### "Module not found" Errors
If you see errors after migration, it is often due to hoisting.
1.  Check if you are referencing a package that isn't in your `dependencies`.
2.  Try adding `shamefully-hoist=true` to your `.npmrc` file as a temporary diagnostic step.

### Post-install Scripts failing
Some packages rely on `node-gyp`. Ensure you have Python and build tools installed on your system, as pnpm runs scripts much faster and sometimes exposes race conditions in legacy build scripts that npm hides.

### Turborepo / Monorepos
If this project is part of a monorepo using Turborepo, pnpm is the native recommended package manager. Ensure you have a `pnpm-workspace.yaml` file defined at the root if you intend to link local packages.
```