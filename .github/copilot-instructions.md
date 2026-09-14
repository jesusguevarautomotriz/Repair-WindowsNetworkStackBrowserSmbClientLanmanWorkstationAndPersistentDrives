# Copilot project instructions

This repository is a long-lived Windows automation / installer project. Preserve work, avoid destructive refactors, and keep the original operational intent intact.

## Non-negotiable rules
- Do not rewrite working logic just to make it look cleaner.
- Preserve intentionally verbose logging, debug output, and step-by-step execution traces unless the user explicitly asks to remove them.
- Preserve the purpose of the real operational logic in the installer and Windows optimization routines.
- Do not strip out real system-tuning or cleanup behavior.
- Treat Defender as a temporary operational state while the installation job is running, and restore it afterward.
- The main workflow must continue running and return to the caller instead of aborting on a non-critical dependency failure.
- Do not discard previous working code without explicit approval.
- Prefer narrow, minimal edits over broad rewrites.
- Respect the user’s testing phase and do not keep suggesting changes while they explicitly ask for space to validate.
- Preserve the project’s long-term continuity and avoid reworking the same code area repeatedly without a concrete bug.

## Project-specific reminders
- The code has been heavily reworked over time and should be treated as a production area, not disposable generated code.
- The code contains real system tuning and cleanup logic and should be preserved.
- Defender toggling is expected only during the install window; it must be restored afterward.
- The script is a real-world Windows automation project, not an example toy script.
- Stability and continuity matter more than cosmetic cleanup.

## Working style for Copilot
- Read the existing code and repository history before proposing a refactor.
- If a function already exists and is being used, keep it unless the user asks for a change.
- Patch only the exact failing behavior.
- Validate with the actual parser or runtime behavior when relevant.
- Do not assume a refactor is beneficial simply because the code is verbose.

## Decision summary
The user’s intent is clear: preserve the real behavior, keep the purposeful functionality, avoid endless churn, and do not lose months of work during a new session.

This project should be treated as a production artifact with operational continuity as the top priority.
