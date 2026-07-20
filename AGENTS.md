# BiG Lab documentation rule

This rule applies to the entire repository.

- Record every BiG Lab note and research document in a Markdown (`.md`) file.
- Treat Markdown as the canonical source.
- Put a clickable link to the corresponding HTML at the top of every canonical Markdown document, using exactly `[HTML版を開く](relative/path/to/document.html)`.
- Make that link the first non-empty body line. If the document has YAML front matter, place the link immediately after the closing `---`, not before the front matter.
- Use a relative repository path that resolves from the Markdown file, and do not mark the work complete unless the linked HTML file exists.
- In the same task, create or update an HTML (`.html`) rendering that contains the same substantive content.
- Keep the Markdown and HTML synchronized; a note or research update is not complete while only one format is current.
- Use the existing destination and template when a document is already covered by `shared/scripts/build-website.sh` or a topic-specific build script.
- For a new document without an established build mapping, use the same basename and directory for both files where practical. The required top-of-file link records that mapping; also document it in the nearest README when the HTML uses a different basename or directory.
- HTML must contain the rendered content, not only a redirect or a link to the Markdown source.
- Run `shared/scripts/build-website.sh` after documentation changes; it renders the established pages, renders same-basename documents, and validates every Markdown-to-HTML link.
- Agent/configuration Markdown such as `AGENTS.md` is exempt unless it is also intended to be published as a BiG Lab document.
