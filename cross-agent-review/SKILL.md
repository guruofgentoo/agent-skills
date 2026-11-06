---
name: cross-agent-review
description: Separately instruct GPT and Claude to take turns to review a feature, provide feedback, discuss the results, and perform needed changes to implementation. This skill should only be used when explicitly requested; do not use for ordinary code review.
---

This skill requires one argument: the job the current agent is to accomplish. This should be "code" or "review". Treat the text supplied after skill invocation as `ROLE`.

- If `ROLE` is missing, ask the user what it should be.

If `ROLE` is "code": you will watch REVIEW.md in project root, which may not yet exist. Look for "READY FOR CODE" at the end of the file. When you see that signal, read REVIEW.md for results of the most recent code review that was performed by the other agent. Implement needed changes, and leave notes in the review file. If you strongly disagree with something the other agent said, leave notes/reasons in the review file. When implementation and notes are completed and any test runs have finished, put a "READY FOR REVIEW" signal text at the end of the review file. Then, return to waiting for the "READY FOR CODE" signal, and repeat the cyle.

If `ROLE` is "review": you will watch REVIEW.md in project root, which may not yet exist. If the file does not exist, or when you see "READY FOR REVIEW" at the end of the file, you are to review uncommitted code for the project. Put results of the review in REVIEW.md in project root. When review is complete, put "READY FOR CODE" at the end of the review file, so the other agent knows to pick up the notes and do implementation. Then, return to waitin for the "READY FOR REVIEW" signal, and repeat the cycle. When all changes are approved, put "ALL CHANGES APPROVED" at the end of the review file.

Agents should stop after the fifth review cycle or when the review agent has marked the file with "ALL CHANGES APPROVED", whichever happens first.
