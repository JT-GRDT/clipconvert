1. **What `git rebase` does**\\
    `git rebase` moves your branch's commits so they are based on a different commit. It effectively creates a cleaner, more linear history.
2. **Example starting point**
    Suppose your history looks like this:

   ```
   A---B---C  main
        \\
         D---E  feature
   ```
    While you were working on `feature`, `main` received commit `C`.
3. **Run rebase**

   ```
   git switch feature
   git rebase main
   ```
    Git takes your feature commits `D` and `E` and reapplies them on top of `C`.
4. **The result**

   ```
   A---B---C---D'---E'  feature
   ```
    `D'` and `E'` are new commits containing the changes from `D` and `E`. Their commit IDs change because their history has changed.
5. **Why use it?**\\
    Rebase is commonly used to incorporate the latest changes from another branch while keeping a linear project history.
6. **Be careful with shared branches**\\
    Because rebase rewrites commit history, avoid rebasing commits that other people have already based work on. For a private feature branch, however, rebasing is often convenient.
7. **Interactive rebase**\\
    You can also clean up several commits before sharing them:

   ```
   git rebase -i HEAD~3
   ```
    This opens an editor where you can, for example, reorder commits, squash several commits into one, or edit commit messages.

 **Rule of thumb:** `merge` preserves the existing branch history, while `rebase` rewrites your branch's commits onto a new base to produce a linear history.
