# 从现有 ledger 恢复

属于 superpowers:subagent-driven-development。该 plan 的 workspace 已有 ledger，位于 `<workspace>/progress.md`。

如果 ledger 第一行指向你的 plan 文件，则含 `Task <N>: complete` 行的 tasks 已经完成——不要重新 dispatch；从第一个没有该行的 task 恢复。最后一个行是 fix round 的 task 处于循环中：从下一轮恢复。如果 ledger 第一行指向另一个 plan 文件——或旧扁平路径 `.superpowers/sdd/progress.md` 上有一个游离 ledger——那是其他 plan 的进度：保持原样，为自己新建 ledger。
