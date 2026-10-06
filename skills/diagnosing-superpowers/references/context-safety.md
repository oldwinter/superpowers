# Context safety for session transcripts

> 中文摘要：任何 transcript 都必须先测量，再按行号和字段小范围读取；禁止为内容直接 `cat`/`grep`，单条输出不得超过 500 字符，并保持 session 文件只读。以下英文保留为精确操作规范。

One transcript record can exceed a megabyte or embed a whole history. Printing
one whole record can overflow the context of the session doing the diagnosis.
Every reader of a session file, controller or subagent, follows these rules for
every file, every time.

1. **Measure before reading.**

   ```bash
   wc -lc "$F"
   awk '{ if (length($0) > 100000) print NR, length($0) }' "$F"   # long lines
   ```

2. **Never `cat` or `grep` for content.** Get line numbers and counts
   first (`grep -n … | cut -d: -f1`, `jq -r '.type' | sort | uniq -c`),
   then small fields from specific lines (`sed -n Np | jq -c '{…}'` or
   `| cut -c1-500`). Use the field-extraction commands established during
   discovery for the source in front of you.
3. **Narrow anything over 500 characters.** If a command returns more than
   500 characters for one record, tighten the field or the slice.
4. **Read-only.** Never modify, move, or delete a session file.
