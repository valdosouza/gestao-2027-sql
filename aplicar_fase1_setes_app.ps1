# =====================================================================
# setes-app Fase 1 — aplica as tabelas centrais e confere o resultado
# Uso:  .\aplicar_fase1_setes_app.ps1            (localhost/root, pede senha)
#       .\aplicar_fase1_setes_app.ps1 -User outro -DbHost 192.168.0.10
# Requisito: mysql.exe no PATH (MySQL/MariaDB client)
# =====================================================================
param(
  [string]$DbHost = "localhost",
  [int]   $Port   = 3306,
  [string]$User   = "root"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ddl = Join-Path $scriptDir "01_setes_central_ddl.sql"

if (-not (Get-Command mysql -ErrorAction SilentlyContinue)) {
  Write-Host "ERRO: mysql.exe nao encontrado no PATH." -ForegroundColor Red
  Write-Host "Alternativa: abra o Workbench/HeidiSQL e execute $ddl manualmente."
  exit 1
}

$pwd = Read-Host "Senha do MySQL para '$User'" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))

Write-Host "`n[1/3] Aplicando 01_setes_central_ddl.sql (re-executavel, IF NOT EXISTS)..." -ForegroundColor Cyan
Get-Content $ddl -Raw | mysql -h $DbHost -P $Port -u $User --password=$plain
if ($LASTEXITCODE -ne 0) { Write-Host "Falha ao aplicar o DDL." -ForegroundColor Red; exit 1 }

Write-Host "[2/3] Conferindo as tabelas novas da central..." -ForegroundColor Cyan
$check = @"
SELECT table_name FROM information_schema.tables
WHERE table_schema='setes_central'
  AND table_name IN ('tb_user_has_preference','tb_institution_theme');
"@
$found = $check | mysql -h $DbHost -P $Port -u $User --password=$plain -N
Write-Host $found
if (($found -split "`n").Count -lt 2) {
  Write-Host "ATENCAO: nem todas as tabelas novas foram encontradas." -ForegroundColor Yellow; exit 1
}

Write-Host "[3/3] Central OK. Agora suba a API para a migration 003 rodar nos schemas de cliente:" -ForegroundColor Green
Write-Host "      cd D:\Gestao2027\setes-api ; npm run dev"
Write-Host "      No log, procure: 'Migration aplicada: 003 - setes_app_fase1'"
Write-Host "`nPara conferir depois, por schema:" -ForegroundColor Cyan
Write-Host "      SELECT * FROM setes_setes._migrations;   -- deve listar 001, 002 e 003"
