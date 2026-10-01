# Protected acceptance tests

Files in this folder prove that a slice is done. They are written by the QA Engineer on a `qa/` branch,
must fail before the feature exists, and are merged only after review.

After merge they are protected:
- Claude Code hooks block every other role from editing them;
- the pipeline's protected-path check fails any non-`qa/` branch that changes them;
- a branch policy requires the Tech Lead's review for any change here.
