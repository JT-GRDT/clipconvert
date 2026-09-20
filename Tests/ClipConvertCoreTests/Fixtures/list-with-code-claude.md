## What `git rebase` does

Rebase takes the commits from your current branch and replays them on top of another branch, creating a linear history instead of a merge commit.

1. **Find the common ancestor** — Git identifies the point where your branch diverged from the target branch (e.g., `main`).
2. **Save your commits temporarily** — Git sets aside the commits unique to your branch since that divergence point.
3. **Reset your branch** — Your branch pointer is moved to the tip of the target branch.
4. **Replay each commit one by one** — Git reapplies your saved commits on top of the new base, generating new commit hashes for each.
5. **Resolve conflicts if any arise** — If a commit can't apply cleanly, rebase pauses so you can fix the conflict, then you run `git rebase --continue`.
6. **Finish with a linear history** — Once all commits are replayed, your branch looks like it was built directly on top of the latest target branch, with no merge commit.

## Code example

```bash
# Start on your feature branch
git checkout feature-branch

# Rebase it onto the latest main
git rebase main

# If there's a conflict, git pauses and shows you the conflicted files
# Edit the files to resolve conflicts, then:
git add <resolved-file>
git rebase --continue

# If you want to abort and go back to how things were:
git rebase --abort

# Once done, your feature branch has main's latest commits underneath it,
# with your commits replayed on top — no merge commit involved
```

**Before rebase:**
```
main:     A---B---C
                \\
feature:         D---E
```

**After `git rebase main` (while on feature):**
```
main:     A---B---C
                    \\
feature:             D'---E'
```

Note: `D'` and `E'` are new commits with different hashes — this is why you should avoid rebasing commits that have already been pushed and shared with others, since it rewrites history.
