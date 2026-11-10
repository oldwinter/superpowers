# 批量处理小型同形工作

属于 superpowers:subagent-driven-development。

**批量处理小型同形工作。** 当 plan 列出多个 task，且每个都是同一种小型、独立的编辑——相同的一行修复、常量修改或字段添加，在多个文件中重复——不要为每个 task dispatch 一个 subagent。编写一份 dispatch brief，列出每个文件及其变更，把整批交给一个 subagent，并把它的 diff 作为一个单元 review。只有当工作需要自己的判断、自己的测试或自己的 review 面时，才保留一 task 一 dispatch。
