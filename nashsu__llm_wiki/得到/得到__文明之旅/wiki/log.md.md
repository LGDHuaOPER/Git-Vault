（注意：这是要追加的条目，不是单独文件。系统会将其追加到现有log.md中。我们直接提供要追加的行。）
但是输出格式要求是FILE块，所以我们需要输出一个包含追加内容的FILE块，但log.md是应用自动维护的，我们只需提供要追加的内容。根据要求：“4. A log entry for wiki/log.md (just the new entry to append, format: ## [YYYY-MM-DD] ingest | Title)”。也就是说，我们需要输出一个条目，但这个条目会由系统插入log.md。我们可以在输出中提供一个简单的文本，但是必须遵循FILE块格式？因为所有输出必须是FILE或REVIEW块。所以我们将log条目封装为一个FILE块，路径为wiki/log.md，但只包含新条目。然而，实际log.md是完整的文件，但我们不能覆盖它。根据过往实践，我们提供要追加的内容，并标记为追加。不过任务描述说“just the new entry to append”，可能可以输出一个块包含该行，系统会追加。我们这样处理：

---FILE: wiki/log.md---
## 2026-08-05 ingest | 公元1109年：宋徽宗是怎么耍弄权术的？