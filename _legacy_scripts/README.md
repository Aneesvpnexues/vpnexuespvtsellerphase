# Legacy one-off scripts

These did blind text replacements on files under `lib/screens` to apply
earlier UI fixes. They were kept rather than deleted because this folder is
not under version control, so a delete could not be undone.

Do not run them: they rewrite Dart source by pattern-matching, so they will
clobber any edits made since.
