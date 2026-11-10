# 处理不是 DONE 的报告

属于 superpowers:subagent-driven-development。

**DONE_WITH_CONCERNS：** Implementer 完成了工作，但标记了疑虑。继续之前先阅读这些疑虑。如果疑虑涉及正确性或范围，在 review 前处理。如果只是观察（例如“这个文件越来越大”），记录后继续 review。

**NEEDS_CONTEXT：** Implementer 需要未提供的信息。提供缺失的上下文并重新 dispatch。

**BLOCKED：** Implementer 无法完成 task。评估 blocker：
1. 如果是上下文问题，提供更多上下文，用同一 model 重新 dispatch
2. 如果 task 需要更多推理，用更强的 model 重新 dispatch
3. 如果 task 太大，拆成更小的部分
4. 如果 plan 本身有错，裁决修正，写入 ledger，并在 dispatch 中携带 ruling 重新 dispatch

**绝不**忽略升级请求，也不要在没有任何变更的情况下强迫同一 model 重试。如果 implementer 说卡住了，就必须改变某些东西。
