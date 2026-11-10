# Pre-flight 扫描

属于 superpowers:subagent-driven-development。在 dispatch Task 1 之前运行一次。

在 dispatch Task 1 之前，扫描 plan 一次以查找冲突，并在检查时写下你检查了什么：

- 相互矛盾，或与 plan 的 Global Constraints 矛盾的 tasks
- plan 明确要求、但 review rubric 视为缺陷的任何内容（没有断言的测试、逻辑块的逐字重复）

扫描的输出是一张表，而不是一个结论。每一对共享文件或接口的 tasks 写一行：两个 tasks、前者产出与后者消费的对照，以及你发现的内容。每个 task 写一行：它自身的文本是否自洽——它指定的测试与它指定的代码、它创建的文件与它后来触碰的文件。“扫描是干净的”若没有这些行，就不是你实际运行过的扫描。

把表写入 ledger。在执行开始前对你发现的所有问题作出裁决——每项 finding 都要对照要求它的 plan 文本——并在 ledger 记录每条 ruling。如果扫描干净，直接继续，不必额外说明。对暴露出的每个冲突作出裁决——spec 是约束性权威，plan 是它的论证——在相应行旁记录 ruling，然后 dispatch Task 1。Review loop 仍然是处理只在实现中出现的冲突的兜底网。
