param(
    [string]$Workspace = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$invader = Join-Path $Workspace 'invader-0.55.0-r4134-33518109-win32\invader-edit.exe'
$tags = Join-Path $Workspace 'Mod Projects\Invader AI Battle 30v30\tags'
$tag = 'levels\test\bloodgulch\bloodgulch.scenario_structure_bsp'

function Read-Values([string]$key) {
    @(& $invader -t $tags -G $key $tag)
}

$planeLines = Read-Values 'collision_bsp[0].planes[*].plane'
$surfacePlanes = Read-Values 'collision_bsp[0].surfaces[*].plane'
$surfaceEdges = Read-Values 'collision_bsp[0].surfaces[*].first_edge'
$edgeStarts = Read-Values 'collision_bsp[0].edges[*].start_vertex'
$edgeEnds = Read-Values 'collision_bsp[0].edges[*].end_vertex'
$edgeForwards = Read-Values 'collision_bsp[0].edges[*].forward_edge'
$edgeReverses = Read-Values 'collision_bsp[0].edges[*].reverse_edge'
$edgeLefts = Read-Values 'collision_bsp[0].edges[*].left_surface'
$edgeRights = Read-Values 'collision_bsp[0].edges[*].right_surface'
$vertexLines = Read-Values 'collision_bsp[0].vertices[*].point'

$planes = foreach ($line in $planeLines) {
    $v = $line -split ','
    [pscustomobject]@{ X=[double]$v[0]; Y=[double]$v[1]; Z=[double]$v[2]; D=[double]$v[3] }
}
$vertices = foreach ($line in $vertexLines) {
    $v = $line -split ','
    [pscustomobject]@{ X=[double]$v[0]; Y=[double]$v[1] }
}

$heights = @{}
for ($surface = 0; $surface -lt $surfacePlanes.Count; $surface++) {
    $planeIndex = [int](([uint32]$surfacePlanes[$surface]) -band 0x7FFFFFFF)
    $plane = $planes[$planeIndex]
    if ([math]::Abs($plane.Z) -lt 0.15) { continue }

    $polygon = [System.Collections.Generic.List[object]]::new()
    $first = [int]$surfaceEdges[$surface]
    $edge = $first
    $guard = 0
    do {
        if ($edge -lt 0 -or $edge -ge $edgeStarts.Count -or $guard++ -gt 128) { break }
        if ([int]$edgeLefts[$edge] -eq $surface) {
            $vertexIndex = [int]$edgeStarts[$edge]
            $next = [int]$edgeForwards[$edge]
        } else {
            $vertexIndex = [int]$edgeEnds[$edge]
            $next = [int]$edgeReverses[$edge]
        }
        $polygon.Add($vertices[$vertexIndex])
        $edge = $next
    } while ($edge -ne $first)
    if ($polygon.Count -lt 3 -or $guard -gt 128) { continue }

    $minX = [math]::Max(0, [math]::Ceiling(($polygon | Measure-Object X -Minimum).Minimum))
    $maxX = [math]::Min(140, [math]::Floor(($polygon | Measure-Object X -Maximum).Maximum))
    $minY = [math]::Max(-200, [math]::Ceiling(($polygon | Measure-Object Y -Minimum).Minimum))
    $maxY = [math]::Min(-40, [math]::Floor(($polygon | Measure-Object Y -Maximum).Maximum))
    if ($minX -gt $maxX -or $minY -gt $maxY) { continue }

    for ($x = $minX; $x -le $maxX; $x++) {
        for ($y = $minY; $y -le $maxY; $y++) {
            $inside = $false
            $j = $polygon.Count - 1
            for ($i = 0; $i -lt $polygon.Count; $i++) {
                $a = $polygon[$i]; $b = $polygon[$j]
                if ((($a.Y -gt $y) -ne ($b.Y -gt $y)) -and
                    ($x -lt (($b.X - $a.X) * ($y - $a.Y) / ($b.Y - $a.Y) + $a.X))) {
                    $inside = -not $inside
                }
                $j = $i
            }
            if (-not $inside) { continue }
            $z = ($plane.D - $plane.X * $x - $plane.Y * $y) / $plane.Z
            if ($z -lt -5 -or $z -gt 12) { continue }
            $key = "$x,$y"
            if (-not $heights.ContainsKey($key) -or $z -gt $heights[$key]) { $heights[$key] = $z }
        }
    }
}

$rows = foreach ($key in $heights.Keys) {
    $xy = $key -split ','
    [pscustomobject]@{ x=[int]$xy[0]; y=[int]$xy[1]; z=[math]::Round(([double]$heights[$key] + 0.5), 4) }
}
$rows | Sort-Object x,y | ConvertTo-Json -Compress
