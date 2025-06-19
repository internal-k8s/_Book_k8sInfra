@echo off
setlocal enabledelayedexpansion

:: sshpass check and installation (Windows equivalent using plink/pscp)
where plink >nul 2>&1
if errorlevel 1 (
    echo plink not found. Please install PuTTY tools
    exit /b 1
)

where pscp >nul 2>&1
if errorlevel 1 (
    echo pscp not found. Please install PuTTY tools
    exit /b 1
)

:: get kubeconfig from 192.168.1.10 (API Server) to current dir
echo vagrant | pscp -pw vagrant -batch root@192.168.1.10:/root/.kube/config .\kubeconfig
if errorlevel 1 exit /b 1

:: backup current context's config or create dummy
if not exist "%USERPROFILE%\.kube\config" (
    if not exist "%USERPROFILE%\.kube" mkdir "%USERPROFILE%\.kube"
    type nul > "%USERPROFILE%\.kube\config"
) else (
    if not exist "%USERPROFILE%\tmp" mkdir "%USERPROFILE%\tmp"
    copy "%USERPROFILE%\.kube\config" "%USERPROFILE%\tmp\kubeconfig-backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%" >nul
)

:: flatten kubeconfig (Windows equivalent)
set KUBECONFIG=%USERPROFILE%\tmp\kubeconfig-backup_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%;%cd%\kubeconfig
kubectl config view --flatten > "%USERPROFILE%\.kube\config"
if errorlevel 1 exit /b 1

:: clear downloaded kubeconfig
del .\kubeconfig >nul 2>&1

echo Successfully flatten kubeconfig
