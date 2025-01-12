## Helper to synchronize files to and from recipes-ps1 Git worktree

Define location of Git worktree in `.env.bat`:

```dosbatch
SET WORKTREE=..\recipes-ps1
```

Run `recipes.bat` to generate those files:

- `recipes-to-bcomp.bat`: compare all files to/from worktree using Beyond Compare
- `recipes-to-repo.bat`: copy (overwrite) all file to worktree

All `.ini` files are not used for now.
