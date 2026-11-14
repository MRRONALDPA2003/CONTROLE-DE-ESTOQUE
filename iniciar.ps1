# Abre o Estoque Fácil com 1 clique.
#   iniciar.ps1 -Abrir site   -> painel web no navegador
#   iniciar.ps1 -Abrir app    -> app Flutter em janela de aplicativo
#   iniciar.ps1 -Abrir parar  -> desliga o servidor
param([ValidateSet('site', 'app', 'parar')][string]$Abrir = 'site')

$ErrorActionPreference = 'Stop'
$raiz    = $PSScriptRoot
$apiDir  = Join-Path $raiz 'api\Estoque.Api'
$exe     = Join-Path $apiDir 'bin\Release\net8.0\Estoque.Api.exe'
$appDir  = Join-Path $raiz 'app'
$url     = 'http://localhost:5000'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

Add-Type -AssemblyName System.Windows.Forms
function Aviso($msg) { [System.Windows.Forms.MessageBox]::Show($msg, 'Estoque Fácil') | Out-Null }

function ApiNoAr {
    try { (Invoke-WebRequest "$url/swagger/v1/swagger.json" -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch { $false }
}

if ($Abrir -eq 'parar') {
    Get-Process Estoque.Api -ErrorAction SilentlyContinue | Stop-Process -Force
    Aviso 'Servidor desligado.'
    return
}

try {
    # SQL Server precisa estar ligado
    $sql = Get-Service 'MSSQL$SQLEXPRESS' -ErrorAction SilentlyContinue
    if ($sql -and $sql.Status -ne 'Running') { Start-Service $sql }

    # App Flutter: compila para web na primeira vez (demora ~1–2 min)
    if ($Abrir -eq 'app' -and -not (Test-Path (Join-Path $appDir 'build\web\index.html'))) {
        Aviso 'Primeira abertura do app: vou compilar (1–2 minutos). Clique OK e aguarde.'
        Push-Location $appDir
        flutter build web --base-href /app/ | Out-Null
        Pop-Location
        Get-Process Estoque.Api -ErrorAction SilentlyContinue | Stop-Process -Force  # recarrega /app
    }

    # API: compila (incremental) e sobe escondida, se ainda não estiver no ar
    if (-not (ApiNoAr)) {
        Push-Location $apiDir
        dotnet build -c Release --nologo -v q | Out-Null
        Pop-Location
        if (-not (Test-Path $exe)) { throw 'Falha ao compilar a API. Abra o código e rode "dotnet build".' }

        $env:ASPNETCORE_ENVIRONMENT = 'Development'
        $env:ASPNETCORE_URLS = 'http://0.0.0.0:5000'
        Start-Process $exe -WorkingDirectory $apiDir -WindowStyle Hidden

        $ok = $false
        for ($i = 0; $i -lt 60; $i++) { Start-Sleep -Milliseconds 500; if (ApiNoAr) { $ok = $true; break } }
        if (-not $ok) { throw 'A API não respondeu. Verifique se o SQL Server está instalado e ligado.' }
    }

    if ($Abrir -eq 'app') {
        $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
                  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($edge) { Start-Process $edge "--app=$url/app/ --window-size=430,880" }
        else { Start-Process "$url/app/" }
    } else {
        Start-Process $url
    }
} catch {
    Aviso "Não foi possível abrir: $($_.Exception.Message)"
}
