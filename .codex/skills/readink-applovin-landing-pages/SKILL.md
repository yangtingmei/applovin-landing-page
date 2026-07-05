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

   Do not ask the user for target language, template path, or hero assets as required inputs. Infer and resolve those automatically.

2. Resolve defaults:
   - Infer the page UI and marketing-copy language from the free chapter language, and keep the landing page consistent with it.
   - Use the embedded standard Readink template inside `scripts/generate-readink-batch.ps1`, derived from the first template the user provided. Do not read the original `readink_reader_...html` file on normal runs.
   - Generate hero images from the free chapters and creative angles by default. Use supplied hero assets only when the user provides them.
   - Default to 10 LPs when the user asks for a batch; otherwise generate the requested count.

3. Read `references/workflow.md` before implementing a batch or changing rules. It contains the durable creative, naming, content, QA, and delivery rules.

4. Analyze the free chapters before writing creative:
   - Identify the heroine, power dynamic, strongest humiliation/rescue/reveal/cliffhanger beats.
   - Pick one primary conversion angle per LP.
   - Keep hero image, hook, genre tags, end card, and reader comment aligned to the same angle.

5. Generate project-bound hero images:
   - Use the `imagegen` skill if available.
   - Save/copy the final images into the delivery folder under `assets/`.
   - Use cinematic, mobile-readable scenes. Avoid visible explicit sexual imagery, nudity, or underage sexualization in marketing images.

6. Generate the landing pages:
   - Prefer the bundled script `scripts/generate-readink-batch.ps1` when creating batches.
   - Provide a creative JSON config with one object per LP.
   - Preserve the supplied chapter text by default. Do not rewrite, abridge, delete, or soften chapter body text unless the user explicitly asks.

7. Deliver a complete package:
   - `current-latest.html`
   - `html/` with formal LP filenames.
   - `assets/` with final hero images.
   - `qa/qa_report.md`
   - `qa/hero contact sheet.jpg` when images are available.
   - `01_creative_matrix.md`
   - `02_preview-index.html`

## Batch Script

Use `scripts/generate-readink-batch.ps1` after preparing:

- A free chapter text file.
- A creative config JSON file.
- Generated or supplied hero assets in the output `assets/` folder whose filenames match each creative config item.

The script uses its embedded standard Readink template by default. Pass `-TemplatePath` only as a legacy/debug override when intentionally refreshing or comparing against an external template.

Example command:

```powershell
powershell -ExecutionPolicy Bypass -File .codex\skills\readink-applovin-landing-pages\scripts\generate-readink-batch.ps1 `
  -BookId "6960a0b216318efdff52cd77" `
  -BookName "Mated to Her Alpha Instructor" `
  -ChapterPath "C:\path\to\chapters.txt" `
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
- Preserve the real Readink PNG header icon and `.ahead .lg img` styling; never replace it with a text, gradient, or placeholder app icon.
- Use the formal filename format from `references/workflow.md`.
- Always create or update `current-latest.html`.
- Keep UI language consistent with chapter language.
- Preserve free chapters as supplied unless the user explicitly asks for edits.
- Keep the embedded template sanitized; do not store full sample chapters, old-book body text, old-book marketing copy, or old-book hero images in the script template.
- Run QA before final delivery and report any checks that could not be completed.
