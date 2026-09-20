`git rebase` is a Git command used to integrate changes from one branch into another by moving or "replaying" a sequence of commits on top of a new base commit.

Unlike `git merge`, which creates a new merge commit with two parent histories, `git rebase` rewrites history to create a linear, cleaner project timeline.

---

### Step-by-Step Execution

1. **Switch to your working feature branch.** Make sure you are on the branch containing the commits you want to move.
2. **Fetch the latest remote updates.** Ensure your local repository has the most recent changes from the remote server.
3. **Execute the rebase command against the target branch.** Run `git rebase main` (or your target branch name). Git finds the common ancestor, temporarly stashes your local commits, updates your local branch to match `main`, and then replays your commits one by one on top.
4. **Resolve any merge conflicts (if prompted).** If Git encounters a conflict while replaying a commit, it pauses. Fix the conflicting files manually, stage them with `git add <file>`, and run `git rebase --continue`.
5. **Push the updated branch.** Since rebasing rewrites commit hashes, if you have already pushed your branch previously, you will need to force push using `git push --force-with-lease` to update the remote reference safely.

---

### Code Example

Assuming you are working on a branch named `feature/login` and want to incorporate the latest changes from `main`:

```bash
# 1. Switch to your feature branch
git checkout feature/login

# 2. Fetch the latest changes from the remote repository
git fetch origin

# 3. Start the rebase process onto the updated main branch
git rebase origin/main

# --- If conflicts occur: ---
# Fix conflict markers in the affected files, then:
git add .
git rebase --continue
# ---------------------------

# 4. Push the rebased commits to your remote branch safely
git push --force-with-lease origin feature/login

```
