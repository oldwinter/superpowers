# “无法从 diff 验证”的条目

属于 superpowers:subagent-driven-development。

Task reviewer 可能报告 “⚠️ Cannot verify from diff” 条目——这些要求位于未变更的代码中，或跨越多个 tasks。它们不会阻塞 review 的其余部分，但在标记 task 完成前，你必须自己解决每一项：你拥有 reviewer 所缺的 plan 和跨 task 上下文。如果你确认某项是真实缺口，就把它当作 spec review 失败——它与其他 findings 一起进入 fix loop。
