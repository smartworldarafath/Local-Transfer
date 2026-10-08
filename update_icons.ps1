Add-Type -AssemblyName System.Drawing

$sourcePath = "C:\Users\Fahad\.gemini\antigravity\brain\fd397c42-b962-4f3c-9006-8b30c6a6ef74\.user_uploaded\media_1791393567530.jpg"
$src = [System.Drawing.Image]::FromFile($sourcePath)

function Resize-Image($width, $height, $destPath) {
    $dir = [System.IO.Path]::GetDirectoryName($destPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.DrawImage($src, 0, 0, $width, $height)
    $g.Dispose()
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created: $destPath ($width x $height)"
}

# 1. Flutter app assets
$appImgDir = "d:\Antigravity Projects\Local Send\app\assets\img"
Resize-Image 512 512 "$appImgDir\logo-512.png"
Resize-Image 512 512 "$appImgDir\logo-512-white.png"
Resize-Image 256 256 "$appImgDir\logo-256.png"
Resize-Image 128 128 "$appImgDir\logo-128.png"
Resize-Image 32 32 "$appImgDir\logo-32.png"
Resize-Image 32 32 "$appImgDir\logo-32-black.png"
Resize-Image 32 32 "$appImgDir\logo-32-white.png"

# 2. Android mipmaps
$androidRes = "d:\Antigravity Projects\Local Send\app\android\app\src\main\res"
Resize-Image 48 48 "$androidRes\mipmap-mdpi\ic_launcher.png"
Resize-Image 48 48 "$androidRes\mipmap-mdpi\ic_launcher_foreground.png"
Resize-Image 72 72 "$androidRes\mipmap-hdpi\ic_launcher.png"
Resize-Image 72 72 "$androidRes\mipmap-hdpi\ic_launcher_foreground.png"
Resize-Image 96 96 "$androidRes\mipmap-xhdpi\ic_launcher.png"
Resize-Image 96 96 "$androidRes\mipmap-xhdpi\ic_launcher_foreground.png"
Resize-Image 144 144 "$androidRes\mipmap-xxhdpi\ic_launcher.png"
Resize-Image 144 144 "$androidRes\mipmap-xxhdpi\ic_launcher_foreground.png"
Resize-Image 192 192 "$androidRes\mipmap-xxxhdpi\ic_launcher.png"
Resize-Image 192 192 "$androidRes\mipmap-xxxhdpi\ic_launcher_foreground.png"
Resize-Image 192 192 "$androidRes\mipmap-xxxhdpi\ic_launcher_round.png"

# 3. Windows & Web assets
$windowsDir = "d:\Antigravity Projects\Local Send\app\windows\runner\resources"
if (Test-Path $windowsDir) {
    Resize-Image 256 256 "$windowsDir\app_icon.png"
}
$webDir = "d:\Antigravity Projects\Local Send\app\web\icons"
if (Test-Path $webDir) {
    Resize-Image 192 192 "$webDir\Icon-192.png"
    Resize-Image 512 512 "$webDir\Icon-512.png"
    Resize-Image 192 192 "$webDir\Icon-maskable-192.png"
    Resize-Image 512 512 "$webDir\Icon-maskable-512.png"
}

$src.Dispose()
Write-Host "All icons replaced successfully!"
