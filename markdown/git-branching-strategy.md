# Next.js Upgrade Branch Workflow

A comprehensive guide for upgrading Next.js versions using git command line and GitHub UI workflows.

## Prerequisites

- Git installed and configured
- VSCode, Warp, or Kiro-CLI terminal
- GitHub account with repository access
- Node.js and npm/yarn/pnpm installed

## Workflow Overview

1. Create feature branch
2. Upgrade Next.js dependencies
3. Test and verify changes
4. Commit and push changes
5. Create Pull Request
6. Review and merge

---

## Step 1: Prepare Your Workspace

### Check current branch and status

```bash
git status
git branch
```

### Ensure you're on main/master and up to date

```bash
git checkout main
git pull origin main
```

### Stash any uncommitted changes (if needed)

```bash
git stash
```

---

## Step 2: Create Upgrade Branch

### Create and checkout new branch

```bash
git checkout -b upgrade/nextjs-v15
```

**Branch naming conventions:**
- `upgrade/nextjs-v15` - for major version upgrades
- `upgrade/nextjs-14.2.5` - for specific version upgrades
- `chore/nextjs-update` - for minor updates

---

## Step 3: Upgrade Next.js Dependencies

### Check current Next.js version

```bash
npm list next react react-dom
```

### Upgrade to latest version

```bash
npm install next@latest react@latest react-dom@latest
```

### Upgrade to specific version

```bash
npm install next@15.0.0 react@18.3.0 react-dom@18.3.0
```

### Using yarn

```bash
yarn upgrade next react react-dom --latest
```

### Using pnpm

```bash
pnpm update next react react-dom --latest
```

### Review package.json changes

```bash
git diff package.json
```

---

## Step 4: Run Codemods (if applicable)

Next.js often provides codemods for major version upgrades.

```bash
npx @next/codemod@latest upgrade
```

### Specific codemods for Next.js 15

```bash
npx @next/codemod@latest app-dir-layout-to-async
npx @next/codemod@latest metadata-to-viewport-export
```

---

## Step 5: Test the Upgrade

### Install dependencies

```bash
npm install
```

### Run development server

```bash
npm run dev
```

### Run build to check for errors

```bash
npm run build
```

### Run tests (if available)

```bash
npm test
npm run test:e2e
```

### Fix any breaking changes or deprecation warnings

Check the console and build output for errors. Refer to Next.js migration guides:
- https://nextjs.org/docs/upgrading

---

## Step 6: Commit Changes

### Stage all changes

```bash
git add .
```

### Stage specific files

```bash
git add package.json package-lock.json
git add src/app/layout.tsx  # example of updated file
```

### Check what's staged

```bash
git status
git diff --staged
```

### Commit with descriptive message

```bash
git commit -m "chore: upgrade Next.js from 14.x to 15.0.0

- Update next, react, and react-dom to latest versions
- Run Next.js codemods for version 15 compatibility
- Fix async metadata API breaking changes
- Update TypeScript types for new API changes
- Verify build passes successfully"
```

### Alternative: Stage and commit interactively

```bash
git add -p  # interactively stage chunks
git commit -v  # open editor with diff for detailed commit message
```

---

## Step 7: Push Branch to GitHub

### Push branch to remote

```bash
git push origin upgrade/nextjs-v15
```

### If branch doesn't exist remotely (first push)

```bash
git push -u origin upgrade/nextjs-v15
```

### View remote branches

```bash
git branch -r
```

---

## Step 8: Create Pull Request (GitHub UI)

### Method 1: GitHub Web Interface

1. Navigate to your repository on GitHub
2. Click **"Compare & pull request"** button (appears after pushing)
3. Or go to **Pull requests** tab → **"New pull request"**

### Fill out PR details:

**Title:**
```
chore: Upgrade Next.js to v15.0.0
```

**Description template:**
```markdown
## Description
Upgrades Next.js from v14.x to v15.0.0 along with React dependencies.

## Changes
- Updated `next` from 14.2.3 → 15.0.0
- Updated `react` and `react-dom` to 18.3.0
- Ran codemods for Next.js 15 compatibility
- Fixed breaking changes in metadata API
- Updated configurations for new App Router features

## Testing
- [x] Development server runs without errors
- [x] Production build completes successfully
- [x] All existing pages render correctly
- [x] No console errors or warnings
- [ ] E2E tests pass (if applicable)

## Breaking Changes
- Async metadata exports now required
- `viewport` separated from metadata object

## Migration Guide Reference
https://nextjs.org/docs/app/building-your-application/upgrading/version-15

## Screenshots
(Add screenshots if UI changes occurred)

## Checklist
- [x] Code follows project conventions
- [x] Dependencies updated in package.json
- [x] Lock file updated
- [x] Build passes
- [x] No new warnings
- [ ] Reviewed by team member
```

4. Select base branch (usually `main` or `develop`)
5. Select compare branch (`upgrade/nextjs-v15`)
6. Add labels: `dependencies`, `enhancement`, `chore`
7. Assign reviewers
8. Link related issues (if any)
9. Click **"Create pull request"**

### Method 2: GitHub CLI (gh)

```bash
gh pr create --title "chore: Upgrade Next.js to v15.0.0" \
  --body "Upgrades Next.js and React dependencies to latest versions" \
  --base main \
  --head upgrade/nextjs-v15 \
  --label dependencies,enhancement
```

### View PR in browser

```bash
gh pr view --web
```

---

## Step 9: Code Review Process

### Request reviews

In GitHub UI:
1. Go to your PR
2. Click **"Reviewers"** on the right sidebar
3. Select team members

### Respond to review comments

```bash
# Make changes based on feedback
git add .
git commit -m "fix: address PR review comments"
git push origin upgrade/nextjs-v15
```

### Keep branch updated with main

```bash
git checkout main
git pull origin main
git checkout upgrade/nextjs-v15
git merge main
# Resolve any conflicts
git push origin upgrade/nextjs-v15
```

### Alternative: Rebase instead of merge

```bash
git checkout upgrade/nextjs-v15
git fetch origin
git rebase origin/main
# Resolve any conflicts
git push origin upgrade/nextjs-v15 --force-with-lease
```

---

## Step 10: Merge Pull Request

### Option A: GitHub UI Merge

1. Ensure all checks pass (CI/CD, tests)
2. Get required approvals
3. Click **"Merge pull request"** button
4. Choose merge strategy:
   - **Merge commit** - preserves all commits
   - **Squash and merge** - combines into single commit (recommended for upgrades)
   - **Rebase and merge** - linear history

5. Confirm merge
6. Delete branch (optional but recommended)

### Option B: Command Line Merge

```bash
git checkout main
git pull origin main
git merge upgrade/nextjs-v15
git push origin main
```

### Delete branch after merge

```bash
# Delete local branch
git branch -d upgrade/nextjs-v15

# Delete remote branch
git push origin --delete upgrade/nextjs-v15
```

### Alternative: GitHub CLI merge

```bash
gh pr merge 123 --squash --delete-branch
```

---

## Step 11: Post-Merge Cleanup

### Update your local main branch

```bash
git checkout main
git pull origin main
```

### Clean up merged branches

```bash
# List merged branches
git branch --merged

# Delete merged local branches
git branch -d upgrade/nextjs-v15

# Prune remote tracking branches
git remote prune origin
```

### Verify upgrade in production

Monitor deployment and check:
- Application starts successfully
- No runtime errors
- Performance metrics stable
- User-facing features work correctly

---

## Troubleshooting Common Issues

### Merge conflicts

```bash
# During merge/rebase
git status  # see conflicting files
# Edit files to resolve conflicts
git add <resolved-files>
git rebase --continue  # if rebasing
git merge --continue   # if merging
```

### Build failures after upgrade

```bash
# Clear cache and reinstall
rm -rf .next node_modules package-lock.json
npm install
npm run build
```

### Reverting a commit

```bash
# Revert last commit
git revert HEAD

# Revert specific commit
git revert <commit-hash>
```

### Reset branch to remote state

```bash
git fetch origin
git reset --hard origin/upgrade/nextjs-v15
```

---

## Best Practices

1. **Always create a feature branch** - never upgrade directly on main
2. **Test thoroughly** - run dev, build, and all test suites
3. **Read migration guides** - check Next.js upgrade documentation
4. **Small, focused commits** - makes review and rollback easier
5. **Descriptive commit messages** - follow conventional commits
6. **Keep PRs manageable** - separate major refactors from dependency upgrades
7. **Document breaking changes** - in PR description
8. **Use semantic versioning** - understand major vs minor vs patch updates
9. **Run codemods first** - before manual changes
10. **Update lockfiles** - always commit package-lock.json/yarn.lock/pnpm-lock.yaml

---

## Quick Reference Commands

```bash
# Create branch and upgrade
git checkout -b upgrade/nextjs-v15
npm install next@latest react@latest react-dom@latest
npm run build

# Commit and push
git add .
git commit -m "chore: upgrade Next.js to v15"
git push -u origin upgrade/nextjs-v15

# Create PR (with gh CLI)
gh pr create --title "chore: Upgrade Next.js" --base main

# Merge and cleanup
gh pr merge --squash --delete-branch
git checkout main && git pull

# Delete local branch
git branch -d upgrade/nextjs-v15
```

---

## Additional Resources

- [Next.js Upgrade Guide](https://nextjs.org/docs/upgrading)
- [Next.js Codemods](https://nextjs.org/docs/app/building-your-application/upgrading/codemods)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Git Documentation](https://git-scm.com/doc)