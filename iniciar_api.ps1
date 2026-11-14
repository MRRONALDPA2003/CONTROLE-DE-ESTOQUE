# Sobe a API + site em http://localhost:5000
Set-Location "$PSScriptRoot\api\Estoque.Api"
$env:ASPNETCORE_ENVIRONMENT = "Development"
Start-Process "http://localhost:5000" | Out-Null
dotnet run --urls "http://0.0.0.0:5000"
