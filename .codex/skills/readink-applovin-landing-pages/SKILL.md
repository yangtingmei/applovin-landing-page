---
name: readink-applovin-landing-pages
description: Create Readink novel HTML landing pages for AppLovin playable/ad traffic. Use when the user provides a book title, Readink book ID, free chapter text, or asks to generate one or many Readink/AppLovin novel landing pages, creative variants, hero images, hooks, end cards, reader comments, QA reports, preview indexes, or reusable delivery packages.
---

# Readink AppLovin Landing Pages

Use this skill to produce Readink-style AppLovin novel landing pages from a book ID, book title, and free chapter text while preserving the standard template, CTA behavior, tracking, layout, and delivery conventions.

## Core Workflow

1. Gather inputs:
   - Book ID.
   - Book title exactly as supplied by the user.
   - Free chapter text file or pasted text.
   - Target language, inferred from the chapters unless the user says otherwise.
   - Number of landing pages, usually 1 or 10.
   - Standard Readink HTML template path.

2. Read `references/workflow.md` before implementing a batch or changing rules. It contains the durable creative, naming, content, QA, and delivery rules.

3. Analyze the free chapters before writing creative:
   - Identify the heroine, power dynamic, strongest humiliation/rescue/reveal/cliffhanger beats.
   - Pick one primary conversion angle per LP.
   - Keep hero image, hook, genre tags, end card, and reader comment aligned to the same angle.

4. Generate project-bound hero images when visual assets are needed:
   - Use the `imagegen` skill if available.
   - Save/copy the final images into the delivery folder under `assets/`.
   - Use cinematic, mobile-readable scenes. Avoid visible explicit sexual imagery, nudity, or underage sexualization in marketing images.

5. Generate the landing pages:
   - Prefer the bundled script `scripts/generate-readink-batch.ps1` when creating batches.
   - Provide a creative JSON config with one object per LP.
   - Preserve the supplied chapter text by default. Do not rewrite, abridge, delete, or soften chapter body text unless the user explicitly asks.

6. Deliver a complete package:
   - `current-latest.html`
   - `html/` with formal LP filenames.
   - `assets/` with final hero images.
   - `qa/qa_report.md`
   - `qa/hero contact sheet.jpg` when images are available.
   - `01_creative_matrix.md`
   - `02_preview-index.html`

## Batch Script

Use `scripts/generate-readink-batch.ps1` after preparing:

- A standard Readink template HTML.
- A free chapter text file.
- A creative config JSON file.
- Hero assets whose filenames match each creative config item.

Example command:

```powershell
powershell -ExecutionPolicy Bypass -File .codex\skills\readink-applovin-landing-pages\scripts\generate-readink-batch.ps1 `
  -BookId "6960a0b216318efdff52cd77" `
  -BookName "Mated to Her Alpha Instructor" `
  -ChapterPath "C:\path\to\chapters.txt" `
  -TemplatePath "C:\path\to\readink_template.html" `
  -CreativeConfigPath "C:\path\to\creatives.json" `
  -RootDir "C:\path\to\output_folder"
```

The JSON config must be an array:

```json
[
  {
    "Seq": "lp01",
    "Angle": "silver healer",
    "Asset": "lp01 silver healer hero.jpg",
    "Hook": "A dying Alpha wolf lay under the moon stones. Eileen touched him with hands everyone called powerless, and silver light answered.",
    "Genre": "Wolfless healer &middot; Dying Alpha &middot; Silver power &middot; Sacred forest &middot; Fated mates",
    "EndTitle": "They called her powerless. The moon disagreed.",
    "EndCopy": "A poisoned Alpha was dying beneath ancient stones. Eileen's hands should have done nothing. Instead, silver light poured out of her.",
    "EndSocial": "This is my favorite trope: the girl everyone dismissed saves the most powerful Alpha alive.",
    "TestGoal": "Test hidden-power awakening and rescue reversal."
  }
]
```

## Non-Negotiables

- Keep the Readink template structure, CSS, layout, CTA placement, `go()` behavior, MRAID/AppLovin tracking, header/footer, and end-card mechanics.
- Use the formal filename format from `references/workflow.md`.
- Always create or update `current-latest.html`.
- Keep UI language consistent with chapter language.
- Preserve free chapters as supplied unless the user explicitly asks for edits.
- Run QA before final delivery and report any checks that could not be completed.
