$ErrorActionPreference='Stop'
$root='C:\Users\mirom\Desktop\Studio 24\RUN24'
$stage=Join-Path $root 'art\source\krita\runner24\ora_stage'
$parts=Join-Path $root 'art\source\krita\runner24\layers'
$merged=Join-Path $root 'art\source\krita\runner24\runner24_merged.png'
$thumb=Join-Path $root 'art\reference\runner24\runner24_master.png'
$ora=Join-Path $root 'art\source\krita\runner24\runner24_master.ora'
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $stage
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'data'),(Join-Path $stage 'Thumbnails') | Out-Null
Set-Content -NoNewline -Encoding ascii -Path (Join-Path $stage 'mimetype') -Value 'image/openraster'
Copy-Item $merged (Join-Path $stage 'mergedimage.png')
Copy-Item $thumb (Join-Path $stage 'Thumbnails\thumbnail.png')
$names=@('scarf_back','leg_back','arm_back','torso','pelvis','leg_front','head','core','arm_front','scarf_front','weapon','paint_accents')
foreach($n in $names){ Copy-Item (Join-Path $parts ($n+'.png')) (Join-Path $stage ('data\'+$n+'.png')) }
$xml=@'
<?xml version="1.0" encoding="UTF-8"?>
<image version="0.0.1" w="1400" h="1800" name="RUNNER 24 Production Master v1">
  <stack name="RUNNER 24">
    <layer name="paint_accents" src="data/paint_accents.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="weapon" src="data/weapon.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="scarf_front" src="data/scarf_front.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="arm_front" src="data/arm_front.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="core" src="data/core.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="head" src="data/head.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="leg_front" src="data/leg_front.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="pelvis" src="data/pelvis.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="torso" src="data/torso.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="arm_back" src="data/arm_back.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="leg_back" src="data/leg_back.png" visibility="visible" composite-op="svg:src-over"/>
    <layer name="scarf_back" src="data/scarf_back.png" visibility="visible" composite-op="svg:src-over"/>
  </stack>
</image>
'@
Set-Content -Encoding utf8 -Path (Join-Path $stage 'stack.xml') -Value $xml
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if(Test-Path $ora){Remove-Item $ora -Force}
$fs=[System.IO.File]::Open($ora,[System.IO.FileMode]::Create)
$zip=New-Object System.IO.Compression.ZipArchive($fs,[System.IO.Compression.ZipArchiveMode]::Create)
$mEntry=$zip.CreateEntry('mimetype',[System.IO.Compression.CompressionLevel]::NoCompression)
$sw=New-Object System.IO.StreamWriter($mEntry.Open(),[System.Text.Encoding]::ASCII)
$sw.Write('image/openraster');$sw.Dispose()
Get-ChildItem $stage -Recurse -File | Where-Object {$_.Name -ne 'mimetype'} | ForEach-Object {
  $rel=$_.FullName.Substring($stage.Length+1).Replace('\','/')
  $entry=$zip.CreateEntry($rel,[System.IO.Compression.CompressionLevel]::Optimal)
  $in=[System.IO.File]::OpenRead($_.FullName)
  $out=$entry.Open();$in.CopyTo($out);$out.Dispose();$in.Dispose()
}
$zip.Dispose();$fs.Dispose()
Write-Output $ora
