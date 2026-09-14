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