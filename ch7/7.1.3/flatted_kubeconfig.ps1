# sshpass equivalent check (using scp from OpenSSH for Windows)
if (!(Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Host "scp not found. Please install OpenSSH for Windows"
    exit 1
}

# get kubeconfig from 192.168.1.10 (API Server) to current dir
sshpass -p vagrant scp -o StrictHostKeyChecking=no root@192.168.1.10:/root/.kube/config ./kubeconfig
if ($LASTEXITCODE -ne 0) { exit 1 }

# backup current context's config or create dummy
$kubeConfigPath = "$env:USERPROFILE\.kube\config"
if (!(Test-Path $kubeConfigPath)) {
    $kubeDir = "$env:USERPROFILE\.kube"
    if (!(Test-Path $kubeDir)) { New-Item -ItemType Directory -Path $kubeDir | Out-Null }
    New-Item -ItemType File -Path $kubeConfigPath | Out-Null
} else {
    $tmpDir = "$env:USERPROFILE\tmp"
    if (!(Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir | Out-Null }
    Copy-Item $kubeConfigPath "$tmpDir\kubeconfig-backup" | Out-Null
}

# flatten kubeconfig
$env:KUBECONFIG = "$env:USERPROFILE\tmp\kubeconfig-backup;.\kubeconfig"
kubectl config view --flatten | Out-File -FilePath $kubeConfigPath -Encoding utf8
if ($LASTEXITCODE -ne 0) { exit 1 }

# clear downloaded kubeconfig
Remove-Item .\kubeconfig -ErrorAction SilentlyContinue

Write-Host "Successfully flatten kubeconfig"

