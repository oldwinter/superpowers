> 中文执行摘要：列出 human prompts 的指令，报告彼此冲突、与 instruction file 冲突、要求绕过规则，以及澄清后改变范围的情况；不评判 partner 对错。以下英文保留为精确执行规范。

Read `prompts/analyst-common.md` first; it gives your role, inputs,
context-safety rules, and the return format. This file adds the dimension.

Dimension: Request conflicts

1. List every human prompt with line and turn. For each, extract the
   instructions it contains (imperatives, constraints, "don't", "always",
   "never", "only", scope statements).
2. Report:
   - two human instructions that cannot both be followed (quote both, with
     lines), and what the assistant did;
   - a human instruction that conflicts with an instruction file loaded in
     the session (CLAUDE.md, AGENTS.md, GEMINI.md, or the harness's
     equivalent; paths are in the case file), quoting both;
   - a human instruction to skip, ignore, or override a step, skill, or
     rule, and what happened afterwards;
   - an instruction the assistant asked to clarify and the answer, when the
     answer changed scope.
3. Do not judge whether your human partner was right. Report the conflict
   and the assistant's resolution.
