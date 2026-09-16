# instructions

This instruction set applies when working on installer, prerequisite, and Windows optimization logic.

## Priority rules
- Preserve working operational intent before making any cleanup or refactor.
- Treat installer and optimization functions as production code, not disposable examples.
- Keep logging and tracing unless the user explicitly asks to remove it.
- Do not rewrite a function simply to make it shorter or more elegant.

## Required behavior
- If a function already exists and is currently used, prefer preserving it unless a concrete bug is identified.
- When a script disables Windows Defender, restore it at the end of the workflow and do not leave it disabled permanently.
- Keep fallback/continue-running behavior in the install flow so the main workflow returns to the caller instead of aborting on a non-critical failure.
- For PowerShell installer tasks, validate using the actual parser or runtime behavior when relevant.

## Refactor guardrails
- Narrow edits are preferred over whole-file rewrites.
- Do not remove valid verbose debug output if it is part of the intended operational behavior.
- If a refactor risks stripping real behavior, stop and ask before continuing.
- Do not remove comments or logging that is part of the intended operational behavior.

## Commit messages and change summaries
- Before suggesting a commit message, inspect the actual working-tree changes with `git status` and `git diff`.
- Describe only changes that are present in the diff; do not describe planned, assumed, or suggested changes as completed.
- Use a specific subject that identifies the affected area and purpose.
- Include a short body listing the meaningful additions, modifications, removals, documentation changes, and behavior changes.
- Explicitly mention important regressions, removed documentation, placeholders, renamed files, or broken references.
- Do not use vague subjects such as "improve code quality", "refactor for maintainability", or "update files" unless the diff truly contains only that change.
- Do not describe a script as refactored unless the diff actually changes its code structure.
- Treat placeholders replacing existing operational documentation as a problem that must be reported.
- Keep commit messages concise, but make the body specific enough to explain the real user-visible or operational impact.