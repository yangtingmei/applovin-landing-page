# Readink AppLovin Landing Page Workflow

## Required Inputs

- Book ID.
- Book title exactly as supplied by the user.
- Free chapter text.
- Target language for page UI and marketing copy.
- Standard Readink HTML template.
- Hero image assets, or permission/context to generate them.
- Optional: number of LPs, author, rating/read count, CTA/deeplink name parameter.

## Template Preservation

- Keep the original Readink page structure, layout, CSS, animation, header, footer, CTA placement, and tracking script.
- Replace only book-specific fields, chapter content, language copy, deeplink, title, hook, genre tags, hero image, and end card.
- Keep all CTA elements clickable through the existing `go()` function.
- Preserve MRAID/AppLovin tracking events: `LOADED`, `DISPLAYED`, `CTA_CLICKED`, and `ENDCARD_SHOWN`.

## Deeplink Rules

- Use:
  `readink:///reader/{bookId}?chapterOrder=1&book={encodedBookTitle}&name={encodedName}`
- Update both the HTML deeplink comment and the `READINK_DEEPLINK` JavaScript variable.
- URL-encode the book title and `name` parameter.
- Keep `chapterOrder=1` unless the user specifies another starting chapter.

## Language Rules

- Match the whole landing page UI to the chapter/book language.
- For English pages, use:
  - `Read for free`
  - `Read for free on Readink`
  - `start reading`
  - `Trending now`
  - `reads`
  - `Continue the story`
  - `Tap to continue in the app`
- Do not leave template-language residue in the header CTA, bottom CTA, rating/read-count text, reading cue, trend/social proof text, end-card CTA, or footer hint text.

## Chapter Content Rules

- Convert chapter headings to the page language, for example `Chapter 1`.
- Preserve POV labels and style them with the existing `.pov` class.
- Convert paragraph breaks into `<p>` tags.
- Add `class="lead"` only to the first real story paragraph.
- If a chapter begins with an author note, keep it as a normal paragraph and make the first story paragraph the lead.
- HTML-escape all chapter text, quotes, apostrophes, and special characters.
- Use the supplied free chapter content as-is by default.
- Do not rewrite, delete, abridge, or soften chapter body text unless the user explicitly asks.

## Marketing Safety

- Do not automatically edit supplied chapter body text for compliance unless the user asks.
- Keep visible marketing surfaces platform-friendly:
  - Avoid explicit sexual imagery in hero images.
  - Avoid nudity in hero images.
  - Avoid visible underage sexualization or ambiguous minor sexual cues.
  - Use symbolic romance tension for sensitive scenes: bond, mark, scent, jacket, door, distance, light, empty bed, or pursuit.

## Creative Pairing Rules

- The hero image, hook, genre tags, end card, reader comment, and free chapters must tell one coherent story angle.
- Do not choose the hero image from the book title alone. Choose it from the strongest emotional scene in the free chapters.
- Treat the hero image as the first conversion frame, not as a book cover.
- Prefer the conversion hinge: the point where the heroine's old life ends and a new, more powerful world opens.
- Good primary angles include:
  - inciting humiliation or rejection
  - escape or irreversible choice
  - first rescue or first meeting
  - secret identity reveal
  - power awakening
  - dangerous protector
  - mate/bond recognition
  - cliffhanger at the end of the free sample
- If the hero image is rescue, all copy should stay on rescue/protection/open-loop logic.
- If the hero image is humiliation, all copy should stay on hurt/reversal/payoff logic.
- If the hero image is mate pursuit, all copy should stay on missing-mate/protective-guilt/trust logic.

## Conversion Copy Rules

- Build one chain per LP: pain -> irreversible action -> new power enters -> unresolved reason.
- The first screen should make the user understand who is vulnerable, what changed, and who or what may change her fate.
- Prefer emotional scene language over plot summary.
- Use concrete sensory and body details when they increase immersion: rain, headlights, shaking hands, ruined card, moonlight, jacket, scent, hospital light, phone glow.
- Keep one unfinished desire:
  - Why does he care?
  - Will she trust him?
  - What will protection cost?
  - Who will pay?
  - What happens when he finds her?
- Strong hook formula:
  `{specific sensory scene}. {heroine's emotional state or impossible choice}. {protector/new power reaction that creates possession, protection, danger, mystery, or reversal}.`
- Strong end-card title should sound like a cliffhanger line or emotional thought, not a section label.
- Reader comments should validate the exact emotion and point to the next paid-reading question.
- Avoid generic comments such as `great story` or `I love this book`.
- Useful reader-comment endings:
  - `That is where I downloaded.`
  - `I needed the next chapter.`
  - `I had to know how he would find her.`

## Hero Image Rules

- Use cinematic, readable scenes that communicate character, emotion, setting, and conflict at first glance.
- Prefer a single heroine, a couple-focused non-explicit composition, or a clear relational action over abstract scenery.
- Include visible story props when they matter: handmade card, jacket, backpack, phone, letter, keys, hospital bed, mansion, arena, wolf, herbs, moon stones.
- Match time and mood to the hook: dawn for escape/new life, night for danger, hospital light for rescue, moon/forest for werewolf fate.
- Keep subjects large enough for mobile.
- Use faces, hands, posture, gaze, and props as conversion signals.
- Leave top/bottom space that works with existing template overlays.
- For single-file ad HTML, embed the final hero image as base64.
- Prefer compressed JPEG for photoreal hero images.
- Keep a project copy of each generated hero image in `assets/`.

## Ten-LP Batch Strategy

Each LP should test a different emotional engine, not the same plot beat with minor wording changes.

For werewolf academy/fated mate books, useful angles include:

- `arena crush`: fragile hope before rejection.
- `moon dance card`: confession object and emotional investment.
- `bet betrayal`: humiliation reveal and anger.
- `ruined invitation`: visual symbol of hope destroyed.
- `forest escape`: irreversible choice and supernatural pull.
- `silver healer`: hidden power awakening.
- `alpha transformation`: dangerous stranger reveal.
- `marked and running`: mate-bond panic without explicit imagery.
- `jacket scent`: male POV realization and missing mate.
- `alpha pursuit`: protective guilt and trust-earning promise.
- `instructor reveal`: title trope payoff and paid-chapter curiosity.

For mafia rescue books, useful angles include:

- `mafia rescue`: heroine collapses before powerful rescuer.
- `silent escape`: runaway decision and hidden bag.
- `black car stranger`: dangerous salvation ambiguity.
- `hospital protection`: powerful protector becomes gentle.
- `safe with him`: safety promise.
- `dangerous family`: found family plus power.
- `typed the truth`: silent confession.
- `revenge promise`: emotional justice.
- `dangerous new home`: threshold into new life.

## File And Folder Rules

Use this folder shape for a 10-LP batch:

```text
{Book title}_{bookId}_10lp_{YYYYMMDD}/
  html/
  assets/
  qa/
  01_creative_matrix.md
  02_preview-index.html
  current-latest.html
```

Formal landing page filenames:

```text
Readink_EN_T1_{YYYYMMDD}_ytm_lp{NN}_{creative angle}_{bookId}_{book title}.html
```

Rules:

- `Readink`, `T1`, and `ytm` are fixed unless the user specifies otherwise.
- Language code should match target language, for example `EN`.
- `lp{NN}` uses two digits: `lp01` through `lp10`.
- Creative angle words use spaces. Do not add hyphens or underscores inside that field.
- Book title must match the user-supplied title. Do not add separators between title words.
- Always maintain `current-latest.html`.
- If there are many versions, make `current-latest.html` the unambiguous latest entry.

## QA Checklist

Before final delivery, verify:

- Book title is correct in `<title>` and hero title.
- Book ID is correct in both deeplink locations.
- Old book title has no visible residue.
- Old template language has no visible residue.
- `current-latest.html` exists and matches the intended latest page.
- Chapter count matches the supplied free chapters.
- Free chapter text is preserved unless the user requested edits.
- Header CTA, bottom CTA, reading cue, trend text, end card, and footer hint are localized.
- End card exists and has a CTA.
- HTML closes with `</body>` and `</html>`.
- `READINK_DEEPLINK` is valid and URL-encoded.
- Embedded base64 is ignored or stripped during residue scans.
- Hero assets exist in `assets/`.
- Contact sheet or visual spot check confirms hero images match creative angles.

## Final Response Shape

Give the user:

- Link to the delivery folder.
- Link to `current-latest.html`.
- Link to `02_preview-index.html`.
- Link to `01_creative_matrix.md`.
- Link to `qa/qa_report.md`.
- Brief QA status.
- Mention any check that could not be completed.
