param(
    [Parameter(Mandatory = $true)][string]$BookId,
    [Parameter(Mandatory = $true)][string]$BookName,
    [Parameter(Mandatory = $true)][string]$ChapterPath,
    [Parameter(Mandatory = $true)][string]$TemplatePath,
    [Parameter(Mandatory = $true)][string]$CreativeConfigPath,
    [Parameter(Mandatory = $true)][string]$RootDir,
    [string]$DateStamp = (Get-Date -Format "yyyyMMdd"),
    [string]$LanguageCode = "EN",
    [string]$Tier = "T1",
    [string]$Campaign = "ytm",
    [string]$ReadCount = "2.4M",
    [string]$Rating = "4.9"
)

$ErrorActionPreference = "Stop"

$htmlDir = Join-Path $RootDir "html"
$assetDir = Join-Path $RootDir "assets"
$qaDir = Join-Path $RootDir "qa"

function Read-Utf8 {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Value)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function HtmlEncode {
    param([string]$Value)
    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Make-Paragraph {
    param([string]$Text, [bool]$Lead)
    $encoded = HtmlEncode (($Text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join " ")
    if ($Lead) {
        return "<p class=`"lead`">$encoded</p>"
    }
    return "<p>$encoded</p>"
}

function Get-FormalFilename {
    param($Creative)
    return "Readink_${LanguageCode}_${Tier}_${DateStamp}_${Campaign}_$($Creative.Seq)_$($Creative.Angle)_${BookId}_${BookName}.html"
}

function Get-WebPath {
    param([string]$Path)
    return $Path.Replace(" ", "%20")
}

function New-ContactSheet {
    param([object[]]$Pages, [string]$Destination)
    Add-Type -AssemblyName System.Drawing
    $thumbW = 180
    $thumbH = 270
    $labelH = 42
    $gap = 14
    $cols = 5
    $rows = [Math]::Ceiling($Pages.Count / $cols)
    $sheetW = ($cols * $thumbW) + (($cols + 1) * $gap)
    $sheetH = ($rows * ($thumbH + $labelH)) + (($rows + 1) * $gap)
    $sheet = New-Object System.Drawing.Bitmap($sheetW, $sheetH, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($sheet)
        try {
            $graphics.Clear([System.Drawing.Color]::FromArgb(17, 17, 17))
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
            $brush = [System.Drawing.Brushes]::White
            for ($i = 0; $i -lt $Pages.Count; $i++) {
                $page = $Pages[$i]
                if (-not (Test-Path -LiteralPath $page.AssetPath)) { continue }
                $col = $i % $cols
                $row = [Math]::Floor($i / $cols)
                $x = $gap + ($col * ($thumbW + $gap))
                $y = $gap + ($row * ($thumbH + $labelH + $gap))
                $img = [System.Drawing.Image]::FromFile($page.AssetPath)
                try {
                    $graphics.DrawImage($img, $x, $y, $thumbW, $thumbH)
                } finally {
                    $img.Dispose()
                }
                $label = "$($page.Seq) $($page.Angle)"
                $graphics.DrawString($label, $font, $brush, $x, $y + $thumbH + 8)
            }
            $font.Dispose()
        } finally {
            $graphics.Dispose()
        }
        $sheet.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    } finally {
        $sheet.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $ChapterPath)) { throw "Chapter file not found: $ChapterPath" }
if (-not (Test-Path -LiteralPath $TemplatePath)) { throw "Template file not found: $TemplatePath" }
if (-not (Test-Path -LiteralPath $CreativeConfigPath)) { throw "Creative config not found: $CreativeConfigPath" }

New-Item -ItemType Directory -Force -Path $RootDir, $htmlDir, $assetDir, $qaDir | Out-Null

$template = Read-Utf8 $TemplatePath
$source = (Read-Utf8 $ChapterPath) -replace "`r`n", "`n"
$source = $source.Trim()
$creatives = Read-Utf8 $CreativeConfigPath | ConvertFrom-Json
if (-not $creatives -or $creatives.Count -eq 0) { throw "Creative config has no items." }

$chapterMatches = [regex]::Matches($source, "(?m)^Chapter\s+(\d+)\.?\s*$")
if ($chapterMatches.Count -eq 0) {
    throw "No chapter headings were found in the supplied chapter text."
}

$readerParts = New-Object System.Collections.Generic.List[string]
$leadUsed = $false
for ($i = 0; $i -lt $chapterMatches.Count; $i++) {
    $match = $chapterMatches[$i]
    $chapterNumber = $match.Groups[1].Value
    $start = $match.Index + $match.Length
    if ($i + 1 -lt $chapterMatches.Count) {
        $end = $chapterMatches[$i + 1].Index
    } else {
        $end = $source.Length
    }

    $chapterText = $source.Substring($start, $end - $start).Trim()
    $readerParts.Add("<div class=`"ctag`">Chapter $chapterNumber</div><div class=`"crule`"></div>")
    $blocks = [regex]::Split($chapterText, "(?:\n\s*){2,}") |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_.Length -gt 0 }

    foreach ($block in $blocks) {
        $normalized = (($block -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join " ")
        if ($normalized -match "^[A-Za-z]+(?:\s+[A-Za-z]+)?'?s?\s*$" -or $normalized -match "^[A-Za-z]+(?:\s+[A-Za-z]+)?'?s?\s+pov\.?$") {
            $readerParts.Add("<div class=`"pov`">$(HtmlEncode $normalized)</div>")
            continue
        }

        $useLead = (-not $leadUsed -and $normalized -notmatch "^\(A/N:")
        $readerParts.Add((Make-Paragraph $normalized $useLead))
        if ($useLead) { $leadUsed = $true }
    }
}
$readerHtml = ($readerParts -join "`n")

$encodedBookName = [System.Uri]::EscapeDataString($BookName)
$titleParts = $BookName -split "\s+"
if ($titleParts.Count -gt 2) {
    $first = HtmlEncode (($titleParts[0..($titleParts.Count - 3)]) -join " ")
    $em = HtmlEncode (($titleParts[($titleParts.Count - 2)..($titleParts.Count - 1)]) -join " ")
    $titleHtml = "$first <span class=`"am`">$em</span>"
} else {
    $titleHtml = HtmlEncode $BookName
}

$generatedPages = New-Object System.Collections.Generic.List[object]

foreach ($creative in $creatives) {
    foreach ($field in @("Seq", "Angle", "Asset", "Hook", "Genre", "EndTitle", "EndCopy", "EndSocial", "TestGoal")) {
        if (-not $creative.$field) { throw "Creative item is missing field '$field'." }
    }

    $assetPath = Join-Path $assetDir $creative.Asset
    if (-not (Test-Path -LiteralPath $assetPath)) {
        throw "Hero image asset not found: $assetPath"
    }

    $fileName = Get-FormalFilename $creative
    $outputPath = Join-Path $htmlDir $fileName
    $nameParam = [System.Uri]::EscapeDataString(([System.IO.Path]::GetFileNameWithoutExtension($fileName)))
    $deeplink = "readink:///reader/$BookId`?chapterOrder=1&book=$encodedBookName&name=$nameParam"
    $deeplinkComment = $deeplink.Replace("&", "&amp;")
    $heroBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($assetPath))

    $page = $template
    $page = $page -replace '<html lang="fr">', '<html lang="en">'
    $page = [regex]::Replace($page, '<title>.*?</title>', "<title>$(HtmlEncode $BookName) - Readink - $($creative.Seq)</title>")
    $page = [regex]::Replace($page, '<!-- Deeplink: .*? -->', "<!-- Deeplink: $deeplinkComment -->")
    $page = [regex]::Replace($page, '<div class="hero js-cta" onclick="go\(\)"><img src="data:image/[^;]+;base64,[^"]*" alt="[^"]*" />', "<div class=`"hero js-cta`" onclick=`"go()`"><img src=`"data:image/jpeg;base64,$heroBase64`" alt=`"$BookName $($creative.Angle)`" />")
    $page = [regex]::Replace($page, '<div class="genre">.*?</div>', "<div class=`"genre`">$($creative.Genre)</div>")
    $page = [regex]::Replace($page, '<div class="title">.*?</div>', "<div class=`"title`">$titleHtml</div>")
    $page = [regex]::Replace($page, '<div class="hook">.*?</div>', "<div class=`"hook`">$(HtmlEncode $creative.Hook)</div>")
    $page = [regex]::Replace($page, '<div class="soc2">.*?</div>', "<div class=`"soc2`"><span class=`"star`">&#9733;&#9733;&#9733;&#9733;&#9733;</span> $ReadCount &middot; &#9733;$Rating &middot; Trending now</div>")
    $page = [regex]::Replace($page, '<div class="cue">.*?</div>', '<div class="cue">&darr; start reading &darr;</div>')
    $page = [regex]::Replace($page, '<main class="reader js-cta" onclick="go\(\)">[\s\S]*?</main>', "<main class=`"reader js-cta`" onclick=`"go()`">`n$readerHtml`n</main>")

    $endSocial = "<span class=`"star`">&#9733;&#9733;&#9733;&#9733;&#9733;</span> &quot;$(HtmlEncode $creative.EndSocial)&quot; - Readink reader"
    $endwrap = "<div class=`"endwrap js-cta`" onclick=`"go()`" id=`"endcard`"><div class=`"lock`">&#128293;</div><div class=`"endt`">$(HtmlEncode $creative.EndTitle)</div><div class=`"ends`">$(HtmlEncode $creative.EndCopy)</div><div class=`"endsoc`">$endSocial</div><div class=`"endcta`">Continue the story &rarr;</div></div>"
    $page = [regex]::Replace($page, '<div class="endwrap js-cta" onclick="go\(\)" id="endcard">[\s\S]*?</div></div><footer', "$endwrap</div><footer")

    $page = [regex]::Replace($page, "var READINK_DEEPLINK='[^']+';", "var READINK_DEEPLINK='$deeplink';")
    $page = $page.Replace('1.9M lectures', "$ReadCount reads")
    $page = $page.Replace('Lire gratuitement sur Readink', 'Read for free on Readink')
    $page = $page.Replace('Lire gratuitement', 'Read for free')
    $page = $page.Replace("Touchez pour continuer dans l'app", 'Tap to continue in the app')

    Write-Utf8NoBom $outputPath $page
    $generatedPages.Add([pscustomobject]@{
        Seq = $creative.Seq
        Angle = $creative.Angle
        FileName = $fileName
        OutputPath = $outputPath
        Asset = $creative.Asset
        AssetPath = $assetPath
        Hook = $creative.Hook
        Genre = $creative.Genre
        EndTitle = $creative.EndTitle
        EndCopy = $creative.EndCopy
        EndSocial = $creative.EndSocial
        TestGoal = $creative.TestGoal
    })
}

Copy-Item -LiteralPath $generatedPages[0].OutputPath -Destination (Join-Path $RootDir "current-latest.html") -Force
New-ContactSheet -Pages $generatedPages.ToArray() -Destination (Join-Path $qaDir "hero contact sheet.jpg")

$matrixLines = New-Object System.Collections.Generic.List[string]
$matrixLines.Add("# $BookName - Landing Page Creative Matrix")
$matrixLines.Add("")
$matrixLines.Add("- Book ID: $BookId")
$matrixLines.Add("- Book title: $BookName")
$matrixLines.Add("- Generation date: $DateStamp")
$matrixLines.Add("- Free chapter policy: supplied chapter content preserved as-is")
$matrixLines.Add("")
$matrixLines.Add("| LP | Creative angle | Hero asset | Hook | Genre | End card | Reader comment | Test goal | HTML |")
$matrixLines.Add("|---|---|---|---|---|---|---|---|---|")
foreach ($pageInfo in $generatedPages) {
    $matrixLines.Add("| $($pageInfo.Seq) | $($pageInfo.Angle) | $($pageInfo.Asset) | $($pageInfo.Hook) | $($pageInfo.Genre -replace '&middot;', ' / ') | $($pageInfo.EndTitle) $($pageInfo.EndCopy) | $($pageInfo.EndSocial) | $($pageInfo.TestGoal) | $($pageInfo.FileName) |")
}
Write-Utf8NoBom (Join-Path $RootDir "01_creative_matrix.md") (($matrixLines -join "`n") + "`n")

$previewCards = New-Object System.Collections.Generic.List[string]
foreach ($pageInfo in $generatedPages) {
    $href = "html/" + (Get-WebPath $pageInfo.FileName)
    $img = "assets/" + (Get-WebPath $pageInfo.Asset)
    $previewCards.Add("<article class=`"card`"><a href=`"$href`"><img src=`"$img`" alt=`"$($pageInfo.Seq) $($pageInfo.Angle)`" /></a><div class=`"body`"><div class=`"seq`">$($pageInfo.Seq) &middot; $($pageInfo.Angle)</div><h2>$(HtmlEncode $pageInfo.Hook)</h2><p>$(HtmlEncode $pageInfo.TestGoal)</p><a class=`"open`" href=`"$href`">Open HTML</a></div></article>")
}

$previewHtml = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>$BookName - LP Preview</title>
<style>
body{margin:0;background:#111;color:#f6f1e9;font-family:Arial,Helvetica,sans-serif}
header{padding:28px 24px 12px;max-width:1180px;margin:auto}
h1{font-size:28px;margin:0 0 8px}
.sub{color:#bfb7aa;font-size:14px}
.grid{max-width:1180px;margin:auto;padding:18px 24px 40px;display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:18px}
.card{background:#1c1c1f;border:1px solid #333;border-radius:8px;overflow:hidden}
.card img{width:100%;aspect-ratio:3/4;object-fit:cover;display:block}
.body{padding:14px}
.seq{font-size:12px;color:#cfc4ff;text-transform:uppercase;letter-spacing:.04em}
h2{font-size:16px;line-height:1.25;margin:8px 0;color:#fff}
p{font-size:13px;line-height:1.45;color:#cfc8bd}
.open{display:inline-block;margin-top:8px;color:#fff;background:#553eff;padding:9px 12px;border-radius:6px;text-decoration:none;font-weight:700}
</style>
</head>
<body>
<header>
<h1>$BookName - Landing Pages</h1>
<div class="sub">Open each card to preview the formal HTML. The recommended/latest default is LP01 and is also copied to current-latest.html.</div>
</header>
<main class="grid">
$($previewCards -join "`n")
</main>
</body>
</html>
"@
Write-Utf8NoBom (Join-Path $RootDir "02_preview-index.html") $previewHtml

$qaLines = New-Object System.Collections.Generic.List[string]
$qaLines.Add("# QA Report - $BookName")
$qaLines.Add("")
$qaLines.Add("| LP | File | Checks |")
$qaLines.Add("|---|---|---|")
$badPatterns = 'Lire|lectures|Tendance|Continuer|Touchez|commencer la lecture|Jeu du Destin|Jeu-du-Destin'
foreach ($pageInfo in $generatedPages) {
    $html = Read-Utf8 $pageInfo.OutputPath
    $visible = [regex]::Replace($html, 'data:image/[^"'']+', 'data:image/omitted')
    $checks = @()
    $checks += "chapters=$([regex]::Matches($html, '<div class=`"ctag`">Chapter ').Count)"
    $checks += "bookId=$($html.Contains($BookId))"
    $checks += "title=$($visible.Contains($BookName))"
    $checks += "englishCTA=$(($visible.Contains('Read for free') -and $visible.Contains('Read for free on Readink') -and $visible.Contains('Continue the story') -and $visible.Contains('Tap to continue in the app')))"
    $checks += "noTemplateResidue=$(-not [regex]::IsMatch($visible, $badPatterns, 'IgnoreCase'))"
    $checks += "hook=$($visible.Contains($pageInfo.Hook.Substring(0, [Math]::Min(40, $pageInfo.Hook.Length))))"
    $checks += "closed=$($html.TrimEnd().EndsWith('</html>'))"
    $qaLines.Add("| $($pageInfo.Seq) | $($pageInfo.FileName) | $($checks -join '; ') |")
}
$qaLines.Add("")
$qaLines.Add("- current-latest.html exists: $(Test-Path -LiteralPath (Join-Path $RootDir 'current-latest.html'))")
$qaLines.Add("- current-latest.html source: $($generatedPages[0].FileName)")
$qaLines.Add("- Generated HTML count: $($generatedPages.Count)")
$qaLines.Add("- Generated hero asset count: $((Get-ChildItem -LiteralPath $assetDir -Filter '*.jpg').Count)")
$qaLines.Add("- Chapter source: $ChapterPath")
$qaLines.Add("- Template source: $TemplatePath")
Write-Utf8NoBom (Join-Path $qaDir "qa_report.md") (($qaLines -join "`n") + "`n")

Write-Host "Created landing pages: $($generatedPages.Count)"
Write-Host "Root: $RootDir"
Write-Host "Current latest: $(Join-Path $RootDir 'current-latest.html')"
