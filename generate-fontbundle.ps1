param(
  [string]$Engine = "docker",
  [string]$Alpine = "3.18"
)

$env:DOCKER_ENGINE = $Engine

if (Get-Command bash -ErrorAction SilentlyContinue) {
    Write-Host "Running using Bash..."
    bash ./generate-fontbundle.sh $Alpine
} else {
    Write-Error "bash not found. Install Git Bash or run inside Play With Docker."
}
