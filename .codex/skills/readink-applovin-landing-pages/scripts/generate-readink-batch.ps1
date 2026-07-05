param(
    [Parameter(Mandatory = $true)][string]$BookId,
    [Parameter(Mandatory = $true)][string]$BookName,
    [Parameter(Mandatory = $true)][string]$ChapterPath,
    [string]$TemplatePath = "", # Optional legacy override; default uses embedded standard template.
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

function Encode-ReadinkParam {
    param([string]$Value)
    return ([System.Uri]::EscapeDataString($Value)).Replace("'", "%27")
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

function Get-ReadinkStandardTemplate {
    return @'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" />
<title>Readink Landing</title>
<!-- Deeplink: readink:///reader/TEMPLATE?chapterOrder=1&amp;book=TEMPLATE&amp;name=TEMPLATE -->
<script src="mraid.js"></script>
<style>

*{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased;-webkit-tap-highlight-color:transparent;}
html{scrollbar-width:none;-ms-overflow-style:none;}
html::-webkit-scrollbar,body::-webkit-scrollbar{width:0;height:0;display:none;}
html,body{width:100%;max-width:100%;min-height:100dvh;background:#0b0d12;color:#efe6d6;font-family:Georgia,'Times New Roman',serif;overflow-x:hidden;}
img{display:block;max-width:100%;}
.js-cta{cursor:pointer;}
.ahead{position:fixed;top:0;left:0;z-index:90;display:flex;align-items:center;justify-content:space-between;width:100%;height:56px;padding:0 12px;background:rgba(12,10,16,.95);backdrop-filter:blur(7px);-webkit-backdrop-filter:blur(7px);box-shadow:0 1px 0 rgba(255,255,255,.07);}
.ahead .lg{display:flex;align-items:center;gap:8px;font-family:-apple-system,'Segoe UI',Arial,sans-serif;}
.ahead .lg img{width:32px;height:32px;border-radius:8px;}
.ahead .lg .nm{font-size:12.5px;font-weight:800;color:#f6f1e6;line-height:1.18;}
.ahead .lg .rt{font-size:10px;color:#ff8f00;line-height:1.25;}
.ahead .lg .rt em{color:#b7aec6;font-style:normal;}
.ahead .gw{padding:0 14px;height:32px;border-radius:16px;background:#553eff;color:#ffffff;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:12.5px;font-weight:800;display:flex;align-items:center;gap:5px;cursor:pointer;}
.afoot{position:fixed;left:0;bottom:0;z-index:100;width:100%;padding:13px 16px 18px;background:linear-gradient(0deg,#0b0d12 60%,rgba(11,13,18,0));}
.afoot .btn{width:100%;max-width:560px;margin:0 auto;height:53px;border-radius:27px;background:linear-gradient(180deg,#553eff,#3f2dca);color:#ffffff;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:16.5px;font-weight:800;display:flex;align-items:center;justify-content:center;gap:8px;cursor:pointer;box-shadow:0 8px 26px rgba(85,62,255,.34);animation:abreath 1.05s ease-in-out infinite;}
.afoot .sub{text-align:center;margin-top:6px;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:11px;letter-spacing:.06em;color:#9b91ab;}
@keyframes abreath{0%,100%{transform:scale(1);}50%{transform:scale(1.035);}}
.wrap{padding-top:56px;padding-bottom:96px;}
.hero{position:relative;width:100%;background:#07080c;overflow:hidden;cursor:pointer;display:flex;justify-content:center;align-items:center;}
.hero img{max-height:60vh;max-height:60dvh;max-width:100%;width:auto;height:auto;object-fit:contain;display:block;margin:0 auto;}
.hero .scrim{position:absolute;left:0;right:0;bottom:0;height:46%;background:linear-gradient(180deg,rgba(8,9,14,0) 0%,rgba(8,9,14,.55) 60%,#0b0d12 100%);pointer-events:none;}
.hero .genre{position:absolute;top:10px;left:0;right:0;text-align:center;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:10px;letter-spacing:.16em;text-transform:uppercase;color:#cfc4ff;text-shadow:0 1px 8px #000;}
.intro{padding:16px 22px 4px;max-width:640px;margin:0 auto;text-align:center;}
.title{font-size:clamp(24px,6.6vw,36px);line-height:1.07;font-weight:700;text-shadow:0 2px 18px rgba(0,0,0,.8);}
.title .am{color:#b9a8ff;}
.hook{font-size:17.5px;line-height:1.5;color:#b9a8ff;margin:13px auto 0;max-width:560px;font-style:italic;}
.soc2{margin-top:13px;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:12px;letter-spacing:.04em;color:#b8adc9;}
.soc2 .star{color:#b9a8ff;}
.cue{margin-top:15px;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:11.5px;letter-spacing:.2em;text-transform:uppercase;color:#a99bd6;animation:bob 1.8s ease-in-out infinite;}
@keyframes bob{0%,100%{transform:translateY(0);opacity:.72;}50%{transform:translateY(5px);opacity:1;}}
.reader{padding:10px 22px 4px;max-width:640px;margin:0 auto;}
.ctag{font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:11.5px;letter-spacing:.26em;text-transform:uppercase;color:#b9a8ff;text-align:center;margin:26px 0 6px;}
.crule{width:44px;height:1px;background:#553eff;margin:0 auto 20px;}
.srule{width:30px;height:1px;background:#4d3bd6;margin:18px auto;}
.pov{font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:11px;letter-spacing:.22em;text-transform:uppercase;color:#b9a8ff;text-align:center;margin:18px 0 10px;}
.reader p{font-size:17.5px;line-height:1.72;color:#e7dece;margin-bottom:15px;}
.reader p.lead::first-letter{font-size:33px;font-weight:700;color:#b9a8ff;padding-right:3px;float:left;line-height:.92;}
.endwrap{text-align:center;padding:24px 24px 150px;}
.lock{font-size:30px;margin-bottom:6px;}
.endt{font-size:24px;font-weight:700;color:#f6ecdd;margin-bottom:8px;}
.ends{font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:14px;color:#c8bcff;line-height:1.5;margin:0 auto 8px;max-width:440px;}
.endsoc{font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:12px;letter-spacing:.1em;color:#b9a8ff;margin-top:12px;}
.endsoc .star{color:#b9a8ff;}
.endcta{display:inline-block;margin-top:16px;font-family:-apple-system,'Segoe UI',Arial,sans-serif;font-size:14.5px;font-weight:800;color:#ffffff;background:linear-gradient(180deg,#553eff,#3f2dca);padding:15px 34px;border-radius:30px;cursor:pointer;box-shadow:0 8px 24px rgba(85,62,255,.30);}
@media (orientation:landscape){
  .hero{max-height:none;background:#07080c;display:flex;justify-content:center;}
  .hero img{width:auto;max-width:100%;max-height:60vh;max-height:60dvh;height:auto;object-fit:contain;margin:0 auto;}
  .hero .scrim{display:none;}
  .intro{max-width:760px;}.title{font-size:30px;}.hook{font-size:15.5px;}
  .reader{max-width:760px;}.reader p{font-size:16px;}
  .afoot{padding:8px 16px 10px;}.afoot .btn{height:46px;font-size:15px;}
}

</style>
</head>
<body onload="onAssetLoad()">
<header class="ahead"><div class="lg"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAAAACXBIWXMAAAsSAAALEgHS3X78AAAQAElEQVR4AexdCZgbxZX&#x2B;q3WN7LE9PrjPhBgM5g6GmOVaFna5CcGGYHPYYI6YK86BOQJ88AGBEMCsuc2G&#x2B;wgkXIFsQrwsBAgQ9iNACBBuAjGXj7E9Hmk0knrf3y0ZedDIGk13q6tV&#x2B;lRSq49XVX&#x2B;9v&#x2B;rVq0PW5N1s2wSDQavqgIUmvGwU3Fht&#x2B;VISVr55wgQg6hgAqlzuzCqY45JOyHGQb98JYNsFKc4MbHs5oHoBdEGhKN/yFhAsCfEYwBCLKZgQfQycsrYAlr0oA/hydWKFnMs7umIjg6JNfeFV/4Ikwx/hzADQIwoNJGNpDEkNQyqeQDLejkQs4ZyPlWIvCh8YbPk2QWrDiOPAsmag8lMHYjE4OpGMD0UiHkdadCUZTyMuDFGiQ7AzUokKKPD&#x2B;ZXkrMg&#x2B;oHihVQFsijbZkCjEVQ0HSns0JHYTQObmlV1q7AoOcJxBFaQZNgNR4LRak/Kkb1AXqBHWjR3SkR3SF5ywrjpToUCqZhqXkZogVYYsCwbuXRwQoOkqvlIW0JDgulGZmqPTMGJVbdNy7VHsiyQgJKwLUFepMXipJ6hB1KR6LO1aEZcWgxJQuSqvgRfoHTQDLykuCiqL4McQsC5keoDcPseO8SJ6RYRBwdYk61S26ZVlKdE1MaMuCBVG0QQJkNfq8kiZJqZyYOnGQnUwcGduoPPOcQaAeBKhj1LV4LIW2VByWtAaq7FWsR0CfexoigGWxkQJSiSQyOTg1fh&#x2B;55qdBwFcE2CJQ95KJBMQEESIU0chr4ASQTm4qoRCXJoj2me1yoZG4zTMGgUEhQN2jDsYsC6mkqLLKDliePFX/M5ayMTSVAnvp7NzW/6S5M1QIRCwxNIuok0NTbVAl66TeLNZFACVeWCXK35ZUoP3FHnq9EZj7DAJBIECdpG6mxTohCVSdkdZHAJGWLik/m506ZZvbDAKBIkDdXEkCqbTriXy1BKDZk065NX89As09BoFmI&#x2B;CQoE1Blafc1EhQTQIocTG1GeWvAZ&#x2B;5FFYEHBKkLFCHa6XR6u&#x2B;iEj9/m7iY2Mtm09Lffea8QSCMCFBns72QcaqEkOBLF2nftPZDANe3mZfnOFen70Pmt0FABwSou9RhtztQqJrkqgSg7dQmflUONlR9ypw0CGiCAHU4LaaQpaonuAoB8jKoEHN8/dUfMWcNAnohQDM&#x2B;yUUIEJuoT9K/QgAlTKFPlaHPveanQUBLBKjLDEpR3e1V8sAzFScK0mmIm7k9FYiYw2ggwJkLbYkYIM4dVLz6EADO4hX2oCvuicihyUYrI0Cd5uIbZYuJUwFEBQFyaEvGQKZUXDeHBoHIIEDdTiUs2BVrjSsIEJcLcEJkcmwyYhCoQICtAHsASokpVDrvEsBZZ6nAWXWl8&#x2B;bLIBBJBKjjSjrDtqPzgEsAySpnerKnLIfmbRCILAIcHEslAAX35RJAfjnNA9sH97z5jBICJi8rEaCKU9fLDBACFOWi5Xh/5MC8DQKRR4DeIDgMKMCiLaTEEmLTAPMyCLQAAtR1ix1huyiaL0O/lrQDdgtk3GTRIEAEqOvSDwao&#x2B;yjm&#x2B;W3cnzCvVkGAfQDp9oJ7j1pKtRnlb5WSb8F89pdlksBSadcE4o/&#x2B;bjTnDQJRRKCs82L9w10vEMVcmjwZBPpBgP0AXnIJUP7FMyYYBFoAgVVagBbIr8miQaAqAk4LUPWKJicz3UD3CoDfWodSHrIZoCcL5HqA3l6gkAfoty7XWJoUizbJ1JYAjkKIL2vdDYD1NwL4vWrQ49x6kn4nSB7WXhcYMRJIDwESSVeHeoQIyzqBzkXA0iXA8qVwCN&#x2B;bE3IUYDx4LkwNf1oNP9nkB3OiAIk4cMWtwA2/Bq65V88wV9LthHuAa&#x2B;8DbpS8zHtIvh8A5twBXHI9cPbPgFPOAQ6eAmw/UQi/MWDFgBVdQOdigARhy8F/VTEejYEpprYEKBf0kKFuhllj6h6SKWBIOzBsBDBqDLDRJsDWE4A99nWVf&#x2B;aZwMVCiOuEKDf8SshxAzDjB8DOewIdo&#x2B;G0DEuEEF3LgbyYT2WMXITMZzUE9CWA5IbOK7YEcthSb05dWWNtaQ2&#x2B;BRx&#x2B;LHDeVcDND0treAtwzCnAZlsKAaTvsETMpm5pJYpiKrUUQAPIrNYEGEA&#x2B;I39rMglssS1w5EnAVbeLOfVLYPrp0g/aUEwk6Tew/&#x2B;C0CpFHYmAZNAQYGF563C2p3OBrwJQTgJseBC69yTWT2FqyVaB3SW4xb0FAewI43iDJiHn3jwA7zufPAa6TVmGvg&#x2B;C4WOlVYqdZqf6fa4Ur2hOgxctvQDq6oXSqZ18CXH8/sPs&#x2B;YhqJe5Vu1QEJidjN2hMAhgEDVskNvw6c83PpNIsLmcdffApwXKEVWwP9CTDg4jcPlBHYegc4Yyh0pXL0eZl0lsvXWuXbEKBVSrpGPqeeCMy5E1h7PWDRF3BHlzVtWWtks&#x2B;olQ4CqsLTQSQ6mSHY3HQ9wBHriHsDCzwCOHbSCSWQIIIXf0u&#x2B;Kmj4eBy66Djj0aGDR5&#x2B;5gWtRJoD8BSjVYSyuxR5kvu5Q57&#x2B;jw44AlCwG6Sj0SH0ox&#x2B;hMglLDqmSjW9mUSnHQGsPfBAPsEeuamvlTrT4CKJry&#x2B;LJu7aiFQSYKzLgO2mQBwxinP13pO12v6E2Al8ubAKwSo7OWW4LwrgeEd7kxTnvcqjrDIMQQIS0mELB1lZR&#x2B;1BnDK2S4BotgfMAQImeKFMTlcj7D7f8BZkRbG9A0mTYYAg0GvBZ4tm0Lfmw20D4MzkS5K2TYEiFJp&#x2B;pCXsinEBTj7TQK6lvkQSRNFak0AOoDa0k1ELyxRB5SOydPdpZfcsSKgKH2PRlsCcFkgm&#x2B;fXXwY&#x2B;fAd4&#x2B;3VNw9/cdH/0AUB3Yz7ve5k3HEHHKGCf78BZjN&#x2B;wkJA9qC0BuACeynLWicCpU4AfTtM0SK3KtH9/KvC9ycCMg4AfybmrLwAe/aWQ&#x2B;91wacyBhwNDhwJRWVWmLQHKahGLA5zDEk/It8aBm19xATtHXl9/BXjsfmDOhcDMw4BTROnumQcsXljOdfO&#x2B;11oX2G4ikFnRvDR4GbPlpbBmyFqp/GUiaPrNFi3VBmdTLHpbuM3JyNEAz733NjDvCuDYA4CbZWCKc/fLWNMMLB8H9b3XgXB2qyNpg4rTr3i0J4BfwIRBLj0wJDgJMWYtN0V33QhM3x/489Pub94TNAm2&#x2B;xbA9HAVmZuK5n0ONmZDgMEiGODz3DiL7sjOJcDsGcCDd7qRkwTuUTCf3IyMc4QqW6JgYvY&#x2B;lpYiAJtsDueXA397D6n/EocNd&#x2B;fnzL0IeOEp/&#x2B;OrFsP20gqw5bH5J6PVbtDkXOQJQCXv7hYXYyfQ1QV0Z4BMFs73cvnd2QnnNwtTkzJzlixy/CMt3pg54i3ivqBBp338dm5/hZVJ0HF7GV9ECeCukukST8Wy5cAG67&#x2B;PwyZdh5/MnoqrLtsFV1&#x2B;9I668dFec&#x2B;cNjceCBt2KN0Z&#x2B;hsxMgUVxw3efd43B&#x2B;krBD24HPFgC3XRN8Gss7cXOzreBj9y7GyBFAKRv5gsLCRcDXNv47Lr7gEFw/dyxmnHoydtn7bozb&#x2B;lmMHfsiNt/mGfzrvrfgVHG6z7t&#x2B;Y5x79tFYa80FWLSYHg4FyvEOZv8kcSPd&#x2B;Y8AK4To/sVSRbICuM&#x2B;Q7tstakyArxYKlbanR2H5MuCoKXNw7dzxmLD7Q4BdAKTjaC&#x2B;Vw66KIL95PhbLYrd978C86zbFwQfchiXSGvT2Ki1IwI4xd4R&#x2B;6vdfxcPvM5tsBscdytbI77j8kh8ZAlD5czmFjNj4P/7BSZh&#x2B;&#x2B;iwpnQJsaQnsXjh2czUQWXh2Tq7LIJOVXIHTzpmGGdMuxFIhUT6v5JFwm0P0ACVkAPCZ&#x2B;ZLUgN/rbQSUp6QEHLVn0UWGAMWiAu394487G/8&#x2B;WZzlotBF6exC1YmV3FeUzjJbhCNOOB9HTJ6LTrYQdQuoMx4fbuNgGedCceNbH8T3K5L7CPHfbLiFSr83hfxCZAhA5Z&#x2B;409OYNOWnwGKgmAdYO2IAL95fzMkDYk/PmHEaNt/sHcdzJGdC/eZgGacpkwRBJpRjEiRfUWNXaCQIkBdlT4oZcOKxJwBisVCJqcyNKAOfs9lypIEZx8xEQQqXoRFZQT2jpBTpjgyaAHTD8h9tDAGCKul&#x2B;4qFvf8IOj2ODcW8C0smlEvdza/2npRXYdsc/YMvxr6AZfvaaCe1zkfmNxYB/vNfngs8/2fIM7wCMCeQz0LXEs/ZhR3bXne8Ca3&#x2B;vRiZtaVWQBHadeBd65Zhx1EpHs6&#x2B;RAJ/9M/hUcCyiKK1u8DF7E6M0nt4IapYUNv3DZEBo3NjnAPH2eJoOkTdu02fAvx8i0TyV7bEwmkH8czzi4bHomuI4Iu1VpVMzIp8uRoIAHSM&#x2B;wZiRHwJSU3uKk8gbM/pjDB&#x2B;WDf0WgXRHcnYm1xR4isFqhNEM0rgBgPYEoGmSSGaQSIn7xuuSEHltyS4kE939jiOsRj8Cu8x&#x2B;AEdlg16vS/wDy6QPEWlPAGJiF6UHKN4aHnsdbNsS5dcDJipj4OaIjJ94jXkteV5f06Nka&#x2B;SaTX93pgPLV4yC5&#x2B;2Z8Gp59yhQPuOpkYymX6Lyc1losi3YpBSl4lHBRulpbNoTgGuCl3SOwKeffwOQsQBP0YkDH3&#x2B;8OThtml4WT2V7LIwESIjXir55j0XXFJeV0XOaXzVvCvFFK8RpqytpMclBTw/wf385AHRbelUbOYUaE7kvHywmEBD2FoC&#x2B;eM4M5byguoDz6KYVMu4SdmxqZVXUp9bl8F&#x2B;jotJN&#x2B;eQfpzuDYCSBJ6lOiVNpcQLPvTAZKTn2RKaPQjgavt6GPkZQRTTjXNYplYNUFFUua3FKewIQ5bTYve&#x2B;&#x2B;vz7mzz8OGM4zgwskFYYBD/zmTHzy6TCkxLQYnER/n6b5Q1t847H&#x2B;xtNXekbMH65DMC1AX2R8&#x2B;d2/UE6FTqeBX9wxF8s/WhNquAwKiwuz/ydqXOFzMrz/8WvjcNe9F6J9KED5CPGLys8O8Phtg00k/0yP5qchQLC4V4lNYUjaxsJFaZx70Xwgm4AlJODUiCo31zylRgK9i0bggp8&#x2B;jpwMLaRSZISq&#x2B;UyzL3IAbK11gG9sEWxKPv9EoJZWwBAgWNyrxmbbCh0jgNf&#x2B;thXOOOtZ9C7rgBoDqDrtUxWXe9cAli1YH7POfB4ffLgBhguJKBchf9EU2XYnOFM2gkzqgn/AGSFXGhvSGie9WlHbGCU1&#x2B;EuvTMCMk9/ES38Uz5AoseoAVEpCTILkWKnSN5Ve&#x2B;g9KnoGYOk8/NhXHn/wW3npnnCPHZuWPcL8494euYO7WFnRKOf2atb8SPIOO26v4RB28EhUGOW5JjB4FLFy4Fs78yW9w/uzH8cKTk9C9QpoHdmbbJZ1yCH7LuEHX0tF46r&#x2B;PwuxZz&#x2B;OCS&#x2B;6UQa80RnbYjutT7gz3WwHshI7bChi/XfBJ/egDOPuyBh&#x2B;zdzFa3okKjyTW3O3tNoaJJ&#x2B;eFF/fGuRfej&#x2B;NnfoizzvoTrrz0Nvzn5fPk&#x2B;w6cccaLc85VgAAADQBJREFUmCHnL77sdrz62k7oEGIMGULlF80KT3aAftJS6BUTJA8cPbOfG3w8zQ4wTSAOvvkYje&#x2B;iI0kAomZLn4Cjt7TjhwsRurpG4JW/TsTv5h&#x2B;NR387A7&#x2B;ffyRee2MHZLJDHVufZGFzzuf4vA6BO0nveyiw/cTgU/vmX93Wh&#x2B;ZX8LF7F2NkCVAJERWbg1nt7XBq&#x2B;Y4OYITU9nRx0sfP65X363DMGnjLbwKzLnBTawfcX/nL866rWUfsXMTcz5YggJtV/T/Z2eToK3eD20Js/sv/CzJG4SoiryGgF8cdXnkRSKYCitDHaAwBfATXS9Gc68O/UFq&#x2B;FOB/dV1zD5z/EmDNH6TyM0&#x2B;vvQT880NDAGJhgo8IsKblAhcq/tJO8fRsD1xxK5w/rma0zVB&#x2B;xvvEY9L5LgDsY/G3n8Fv2dq3APSDF8QTonsor&#x2B;bi9GKu7eUmV0uXiJLFgV3&#x2B;DbjkRuBKUf6td3BVolnKT7frc08AQU&#x2B;7dnPt/af2BOjJyHC8BP5Zg44hm5X0S2Btz8Uso9YANt8aOGQqcM7lwM0PA&#x2B;fNASb8y6qFH7TZU4790fuARQvF/OGYSvmkxt/aEoDzX7gg&#x2B;&#x2B;LrgTl3Aj&#x2B;TDqGOgR3Zy28W0&#x2B;Y2gHb9PFF4mjkzzwL22Bfg/4Q1Xb9KHiaaYw/fDfAfYppFQK&#x2B;x0JYArDE5B2WbHYGxWwBbbKtxEI8Od1pecx0g6AUtdSmUcu/i/xB8/inArVDcM/p/WjpngXZw2Hdt0xlfJ&#x2B;2l2p/zfh68A&#x2B;CqM&#x2B;d8RD5CTICIIKxxNljBoFT7X3mejDdIXrj6Tr4i8zYEiExRepwRqfnLdv61lwB/f82t/R1SeBxVM8UZAjQT/TDHXar5H5dO&#x2B;QNi&#x2B;owcE&#x2B;bENp42Q4DGsYv8k5zucOX5QPsIaD/tub/Csvq7YM63NgLcav3CWXBGe9vaoMf6iAaKzBCgAdB8f6QZEYjNX472w3eBH00HuNFu&#x2B;7DoKj/zqz0BKsqN&#x2B;TGhAQScjq1yH3zlz8CsowBOuhveEW3lZ461J0Cp3JgXExpBQGqQsreHHd7ZxwPc6qQVlJ9waU8AZsKEQSBQqkHmXgRcOhvgn95F3eypRMsQoBKNFjl2TJ5SXt95AzhpElB2dXKaQ&#x2B;X10m2R/TIEiGzR9p8xmjycan3Tz4FTjwA&#x2B;eBtYY204Hp9mK3//qfbniiGAP7iGXuoj9wI3Xu5ObBvBfZFCn2J/EmgI4A&#x2B;uoZd66NHAltsDXIjTarV&#x2B;ZeEYAlSi0ULHnNN/xAni618RfVdnrWI1BKiFTsSv7XMInB3lupZFPKM1smcIUAOcVrh01Eygtxda/9v7YMopRAQYTDbMs40iMGEXYKfdZeS3RVsBQ4B6NEdGS&#x2B;u5zct7guyYTjvFdYGyQ&#x2B;xlHnSQZQhQTykpOLMhuSzw9ZeBN1/1L3DTKW57SF99PUnz4h6uqd77IGDZUi&#x2B;k6SVDfwIEVDuzdjz/VOD0I4EfH&#x2B;dfOH0qcO7JwSvR1JOA9uEAd34IPvbmxag/AQLELp4EuB24n2F4B5zlh9x9LcCsgTtSfHuKtAKdQcba/Lis5idhkCkQ82SQEup&#x2B;nPsQ&#x2B;RLicFZcUTbJlR4C3PeLupPl2Y1TZFxgnQ0A/uWSZ0JDLsgKefpaMnlD2gFOUvufR4PNPnd7PlzMO25/GGQnPNhcrhqbIcCqeITiFzvAqTRwfxNagYO&#x2B;C2wyDs5qsFCA4XMiDAF8BrhR8Zyq8PabwGP3NSqh8eemn&#x2B;YuiuHue41L0eNJQ4CQlhNbAfYF7r81&#x2B;ATuvKe7GW8rTJEwBAhev&#x2B;qOkQTgPzFysUrdD3l0I6dIsAXgtvMeiawqptknDQGaXQI14mcrQFPo17cF75/nZsN77i9u0YgPjhkC1FDAMFziEsVPFwAP3R18avj3q4yfW9EHH3swMRoCBINzw7GwFRgqblHuy88/AGlYUAMPrrshcMDh0W4FDAEaUIygH&#x2B;FODZ9&#x2B;LK3AXUHHDEw9ERizJhDVbegNAYLXqQHH6LQCw4BH7gm&#x2B;L8AtUg47FqBHKIqDY00kwID1oKUfoC3OvsB9twQPw3eOAjYeC2RWBB&#x2B;33zHqT4CAZoP6XRD1yGdtzL4A/0Wynvu9uoctEDvEnCNE16hXcsMgR38CBDgZrtkFxr4A/z71npuCTwn/sG&#x2B;rbwKcJxR87P7FqD8B/MMmlJLZCvz2V8CiL4JP3vTTgTz/k7kQfNx&#x2B;xWgI4BeyPsnljE3u3NyM6dLbTAB22QvOztE&#x2B;ZS9wsYYAgUMOYJBxcuXW4w8Bi5vQCkw7Dc7aBa6QG2Q2QvG4FYpUmEQMCIGVrUATPEIbfR3YbxIis35YfwK0kBeokiXlViDQvkAJa64f5tLNoEemK/Pv1bH&#x2B;BPAKCc3klFuBO68PMOElj9vI0cCkY&#x2B;AMjqFEigBT4WlU&#x2B;hOgVCieoqKJMLYCf3gEWPBR8AmePA2Iwvph/QkQfNmHJkYuoM9lgTuuCz5JjPuYk4FuGR0eyBSJ4FNaO0ZDgNr4hP4qW4Enfwe8/1bwSd37YGDT8dB6cMwQIHi98TTGeALgqq17b/ZUbN3CODiWy0HbzXUNAeou6vDeyFbgmfnAe01oBXbcFdhpN2C5ppvr6k8Azb0QXtCKG2pxi/NmzBFi&#x2B;o/9PmCJJuk4OCbJZhb0DUb/3bJjK/DsE81pBTbZDOD6YR1bgQAJ4BaU15&#x2B;cquu1TB3lsRVgX&#x2B;D2a5qTeu4lxAX8um2uqz0BmlPc4YyVM0X/9L/AG68Gn74xawHfnqpfX8AQIHhd8S3GWNy1xZsxLsBMHXE8QCJku/lLj6A1AZRgzKWC8uX7mwM/vkfiQQRsBV58BnjpOQ&#x2B;EDVAEy2LGLKCHbtHiAB9u0u3aEoC2PzvAny1wRyM7FwN&#x2B;BY528l9buByQ8TaprOqK1ooBHBu4&#x2B;0YXF3ZM/cKlUu4SwZ848f/GNtok&#x2B;MX7dYFT5SaryjktTnEyGN1up4ndOf0A4MRD/QuUf8p3RaG6AC5LHDBAAT8wbATwzpvAtP2A42W01k9syrJPEvyn7w/MnAxnkpwOOLFYtCUAE8/QkwFoc/Lbr0D5Wu2LI00jTTZ6ZLiQ3S9c&#x2B;solRlytxp3klCaapUkyqerVA1sC1jb89iuU5VdPQTjP0lQjHuW089jvwLgYGLcu06S1J0A41c&#x2B;kShcEDAF0KSmTTl8QMATwBVYjtIxA2L8NAcJeQiZ9viLgEMDptPgajRFuEAgXAmWddwkQrrSZ1BgEfEeAswgYiQXbRpkNPGGCQaAVEKDO2&#x2B;KrtYrIGgK0QombPK6CgEMAOwtLqYRzgSecA88&#x2B;jCCDQDgRcHTdhih/Ao4JVCgCCuZlEGgNBKjrRSGALea/tAAx6QYUwTWdrZF9k8tWR4C6XrRZ61vSAsjbRhExxx/U6tCY/LcCAq6uF8TqiYn2l3JMu4hNQ&#x2B;mn&#x2B;TIIRBIB6jh1HaL&#x2B;kJclwXn39MKYQQ4SHnwYEaFFgOYPdd2uJIBC3OkHxGOhTbdJmEHAEwSo47bY/wqusq9sAWxbbCIFuM0DzMsgEDkEqNuW6DhE18uZW0kApeLI5oogQ8oXzbdBIEoIJKTSz&#x2B;YKQGnsC/JaSQDAoQbicoZMgXkZBCKEAHXa9f6smilR94oTynJaATKl4qw5NAjUjUBYb0zEIbqdF4c/K/ovU7kqAWzldIbZU7ZWve/LJ8yRQUAzBJzav6TP6kvPP/halQA8o&#x2B;LoETspleQPEwwC&#x2B;iPQJrpM298Wb2ff3HyVAHKHLSGbs8FmQw7N2yCgLQLU4WxPUdJfagLkqPJdlQBwfKQ26BGiOVT5gDk2COiCAHWXOmwrmzP/qya7HwJA&#x2B;gIWsjJk1pYAaEPBvAwCGiFAnaXuZnK9oszi/&#x2B;wn7f0SgPfbSEjPuYh0ir9WF8x1g0B4EKDOdosZD1tq8BrJqkkAPle02RIUMcSQgHCYoAEC1NVMj/Rkxau5uuSulgAUYIvrKNtrOyRQPGGCQSCECFA3qfzZXFHMnvoSWB8BSCaR6ZCgDaZPAPMKGwK0&#x2B;YeIbmZ6gaLU/DZIh9Wnsi4CUAwFFosKK7I9SItflb1rnjfBINBsBKiL1Enqpi0VNepUfsirbgLIvaV3Chkxh4o2wAGG&#x2B;nhWejSqXyZfTUGAtT51kLqYpc2PgXdUGyAAYEtLUCwWZMS4F&#x2B;xtm7lDTSn/lo60XOtnczkUi8WvzPGpF5yGCOAKj8ngQgLdPT3IF3MOEZgo95r5NAj4gwBndLKjWyjmRfdyEonY4&#x2B;KkkYOG3oMgQDm&#x2B;FArSGmRk0KwgbZHTIsQBNk8wL4OABwhQlzilgbpVtG1kcgWRStWl8svhIN6UMojH3UctlZaDhDRFvejOdCFfyDu7TLBFYOLlonkbBAaMAHWHOsRanzqVEWuDyxltW6wPGZ8asMAqD3hCgLJcpZJQVrsQAegtZIUIPVBiKHFORvke8x0tBPzKDXVGiWWfL/SgN59BUVybcDq5MU&#x2B;j/H8AAAD//7ZsCcAAAAAGSURBVAMAegwCAf7LgOYAAAAASUVORK5CYII=" alt="Readink" /><div><div class="nm">Readink</div><div class="rt">&#9733;&#9733;&#9733;&#9733;&#9733; <em>4.8 &middot; 2.4M reads</em></div></div></div><div class="gw js-cta" onclick="go()">Read for free</div></header><div class="wrap"><div class="hero js-cta" onclick="go()"><img src="data:image/jpeg;base64," alt="" /><div class="scrim"></div><div class="genre">Romance &middot; Drama</div></div><div class="intro js-cta" onclick="go()"><div class="title">Readink <span class="am">Novel</span></div><div class="hook">Start reading the story.</div><div class="soc2"><span class="star">&#9733;&#9733;&#9733;&#9733;&#9733;</span> 2.4M &amp;middot; &#9733;4.9 &amp;middot; Trending now</div><div class="cue">&darr; start reading &darr;</div></div><main class="reader js-cta" onclick="go()">
<div class="ctag">Chapter 1</div><div class="crule"></div>
<p class="lead">Story begins here.</p>
</main><div class="endwrap js-cta" onclick="go()" id="endcard"><div class="lock">&#128293;</div><div class="endt">Continue reading</div><div class="ends">Unlock the next chapter in the app.</div><div class="endsoc"><span class="star">&#9733;&#9733;&#9733;&#9733;&#9733;</span> &quot;I needed the next chapter.&quot; - Readink reader</div><div class="endcta">Continue the story &rarr;</div></div></div><footer class="afoot"><div class="btn js-cta" onclick="go()">&#128214; Read for free on Readink</div><div class="sub">Tap to continue in the app</div></footer>
<script>
function track(e){try{if(typeof window.ALPlayableAnalytics!=='undefined'&&window.ALPlayableAnalytics){window.ALPlayableAnalytics.trackEvent(e);}}catch(x){}}
var _loaded=false;
function onAssetLoad(){if(_loaded)return;_loaded=true;track('LOADED');track('DISPLAYED');}
var READINK_DEEPLINK='readink:///reader/TEMPLATE?chapterOrder=1&book=TEMPLATE&name=TEMPLATE';function go(){track('CTA_CLICKED');try{if(typeof mraid!=='undefined'&&mraid.open){mraid.open(READINK_DEEPLINK);return;}}catch(x){}try{window.location.href=READINK_DEEPLINK;}catch(e){}}
var _end=false;
function onScroll(){if(_end)return;if((window.innerHeight+window.scrollY)>=(document.body.scrollHeight-130)){_end=true;track('ENDCARD_SHOWN');}}
window.addEventListener('scroll',onScroll,{passive:true});
</script>
</body>
</html>

'@
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
if (-not (Test-Path -LiteralPath $CreativeConfigPath)) { throw "Creative config not found: $CreativeConfigPath" }

if ($TemplatePath -and -not (Test-Path -LiteralPath $TemplatePath)) { throw "Template file not found: $TemplatePath" }

New-Item -ItemType Directory -Force -Path $RootDir, $htmlDir, $assetDir, $qaDir | Out-Null

if ($TemplatePath) { $template = Read-Utf8 $TemplatePath } else { $template = Get-ReadinkStandardTemplate }
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

$encodedBookName = Encode-ReadinkParam $BookName
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
    $nameParam = Encode-ReadinkParam ([System.IO.Path]::GetFileNameWithoutExtension($fileName))
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
    $page = $page.Replace('2.4M reads', "$ReadCount reads")

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

$templateSourceLabel = if ($TemplatePath) { $TemplatePath } else { "embedded standard Readink template" }
$qaLines = New-Object System.Collections.Generic.List[string]
$qaLines.Add("# QA Report - $BookName")
$qaLines.Add("")
$qaLines.Add("| LP | File | Checks |")
$qaLines.Add("|---|---|---|")
$badPatterns = 'Lire|lectures|Tendance|Continuer|Touchez|commencer la lecture|Jeu du Destin|Jeu-du-Destin'
foreach ($pageInfo in $generatedPages) {
    $html = Read-Utf8 $pageInfo.OutputPath
    $visible = [regex]::Replace($html, 'data:image/[^"'']+', 'data:image/omitted')
    $decodedVisible = [System.Net.WebUtility]::HtmlDecode($visible)
    $hookNeedle = $pageInfo.Hook.Substring(0, [Math]::Min(40, $pageInfo.Hook.Length))
    $checks = @()
    $checks += "chapters=$([regex]::Matches($html, '<div class=`"ctag`">Chapter ').Count)"
    $checks += "bookId=$($html.Contains($BookId))"
    $checks += "title=$($decodedVisible.Contains($BookName))"
    $checks += "englishCTA=$(($decodedVisible.Contains('Read for free') -and $decodedVisible.Contains('Read for free on Readink') -and $decodedVisible.Contains('Continue the story') -and $decodedVisible.Contains('Tap to continue in the app')))"
    $checks += "noTemplateResidue=$(-not [regex]::IsMatch($decodedVisible, $badPatterns, 'IgnoreCase'))"
    $checks += "readinkIcon=$(($html.Contains('<header class="ahead"><div class="lg"><img src="data:image/png;base64,') -and -not $html.Contains('class="appicon"')))"
    $checks += "mraid=$($html.Contains('<script src="mraid.js"></script>'))"
    $checks += "bodyOnload=$($html.Contains('<body onload="onAssetLoad()">'))"
    $checks += "hook=$($decodedVisible.Contains($hookNeedle))"
    $checks += "closed=$($html.TrimEnd().EndsWith('</html>'))"
    $qaLines.Add("| $($pageInfo.Seq) | $($pageInfo.FileName) | $($checks -join '; ') |")
}
$qaLines.Add("")
$qaLines.Add("- current-latest.html exists: $(Test-Path -LiteralPath (Join-Path $RootDir 'current-latest.html'))")
$qaLines.Add("- current-latest.html source: $($generatedPages[0].FileName)")
$qaLines.Add("- Generated HTML count: $($generatedPages.Count)")
$qaLines.Add("- Generated hero asset count: $((Get-ChildItem -LiteralPath $assetDir -Filter '*.jpg').Count)")
$qaLines.Add("- Chapter source: $ChapterPath")
$qaLines.Add("- Template source: $templateSourceLabel")
Write-Utf8NoBom (Join-Path $qaDir "qa_report.md") (($qaLines -join "`n") + "`n")

Write-Host "Created landing pages: $($generatedPages.Count)"
Write-Host "Root: $RootDir"
Write-Host "Current latest: $(Join-Path $RootDir 'current-latest.html')"
