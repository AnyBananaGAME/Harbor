param(
    [string]$InputPath = "packages/Protocol/Data/entity-types.json",
    [string]$OutputPath = "packages/Protocol/src/enums/entity-identifier.zig"
)

$entities = Get-Content -Raw $InputPath | ConvertFrom-Json
$names = [System.Collections.Generic.List[string]]::new()
$entries = [System.Collections.Generic.List[object]]::new()
$used = [System.Collections.Generic.HashSet[string]]::new()

foreach ($entity in $entities) {
    $name = ($entity.identifier -replace '^minecraft:', '')
    $parts = $name -split '[^A-Za-z0-9]+' | Where-Object { $_.Length -gt 0 }
    $enumName = ($parts | ForEach-Object {
        if ($_.Length -eq 1) { $_.ToUpperInvariant() }
        else { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) }
    }) -join ''

    if ($enumName.Length -eq 0) { continue }
    if ($enumName[0] -match '[0-9]') { $enumName = "Entity$enumName" }

    $baseName = $enumName
    $suffix = 2
    while (-not $used.Add($enumName)) {
        $enumName = "$baseName$suffix"
        $suffix++
    }

    $names.Add($enumName)
    $entries.Add([PSCustomObject]@{
        Name = $enumName
        Identifier = $entity.identifier
    })
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('const std = @import("std");')
$lines.Add('')
$lines.Add("pub const EntityIdentifier = enum(u16) {")
foreach ($name in $names) {
    $lines.Add("    $name,")
}
$lines.Add("    _,")
$lines.Add('')
$lines.Add('    pub fn toString(self: EntityIdentifier) []const u8 {')
$lines.Add('    return switch (self) {')
foreach ($entry in $entries) {
    $lines.Add("        .$($entry.Name) => `"$($entry.Identifier)`",")
}
$lines.Add('        else => "",')
$lines.Add('    };')
$lines.Add('    }')
$lines.Add('')
$lines.Add('    pub fn fromString(value: []const u8) ?EntityIdentifier {')
foreach ($entry in $entries) {
    $lines.Add("        if (std.mem.eql(u8, value, `"$($entry.Identifier)`")) return .$($entry.Name);")
}
$lines.Add('        return null;')
$lines.Add('    }')
$lines.Add('};')

$parent = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force $parent | Out-Null
$lines | Set-Content -Encoding utf8 $OutputPath
Write-Output "Generated $($names.Count) entity identifiers in $OutputPath"
