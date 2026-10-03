@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
set "APP_HTML=%~dp0我的专属空间.html"
set "EDGE_EXE="
set "FILE_URL="
echo.
echo  🧳 正在启动「我的专属空间」...
echo.
echo     ✅ 本脚本强制使用 Microsoft Edge 打开，不管系统默认浏览器是啥（联想浏览器/Chrome/360都不会跳）。
echo     数据保存在当前 Edge 用户的浏览器中（IndexedDB + localStorage）。
echo     建议：固定用"这台电脑 + 同一个 Edge 用户"打开，数据不会丢。
echo     如果要换电脑：先进入 ⚙️ 设置·备份 → 下载 JSON 备份。
echo.

rem ========== 第 1 步：用 PowerShell 拼标准 file:// URL（中文/空格/括号都正确） ==========
for /f "usebackq delims=" %%U in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$htmlPath = (Resolve-Path -LiteralPath $env:APP_HTML).Path;" ^
  "$builder = New-Object System.UriBuilder;" ^
  "$builder.Scheme = 'file';" ^
  "$builder.Host = '';" ^
  "$builder.Path = $htmlPath.Replace('\','/');" ^
  "$builder.Fragment = '/dashboard';" ^
  "$builder.Uri.AbsoluteUri"`) do (
  set "FILE_URL=%%U"
)
if "%FILE_URL%"=="" (
  echo  [1/5] ❌ 拼 URL 失败，尝试用回退路径...
  set "FILE_URL=file:///%APP_HTML:\=/%%23/dashboard"
)
echo     👉 目标地址：%FILE_URL%
echo.

rem ========== 第 2 步：多层方式轮番尝试，只要有一个能启动 Edge 就走，绝不回退系统默认浏览器 ==========

rem --- 2.1 先查常见安装路径里有没有 msedge.exe（最可靠，优先级最高） ---
set "EDGE_CANDIDATES[0]=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
set "EDGE_CANDIDATES[1]=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
set "EDGE_CANDIDATES[2]=%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe"
set "EDGE_CANDIDATES[3]=%ProgramFiles%\Microsoft\Edge Beta\Application\msedge.exe"
set "EDGE_CANDIDATES[4]=%ProgramFiles(x86)%\Microsoft\Edge Beta\Application\msedge.exe"
set "EDGE_CANDIDATES[5]=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
set "EDGE_CANDIDATES[6]=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
set /a EDGE_IDX=0
:loop_candidates
if !EDGE_IDX! GTR 6 goto skip_candidates
call set "CUR=%%EDGE_CANDIDATES[!EDGE_IDX!]%%"
if exist "!CUR!" (
  echo  [2/5] ✅ 在「!CUR!」找到 Edge，正在打开...
  start "" "!CUR!" "%FILE_URL%"
  goto end_ok
)
set /a EDGE_IDX+=1
goto loop_candidates
:skip_candidates

rem --- 2.2 用 where.exe 全局搜索 msedge.exe ---
echo  [2/5] ⚙️  正在全局搜索 msedge.exe...
for /f "usebackq delims=" %%P in (`where /r "C:\Program Files" msedge.exe 2^>nul`) do (
  if exist "%%P" (
    echo  [3/5] ✅ where.exe 找到：%%P
    start "" "%%P" "%FILE_URL%"
    goto end_ok
  )
)
for /f "usebackq delims=" %%P in (`where msedge.exe 2^>nul`) do (
  if exist "%%P" (
    echo  [3/5] ✅ PATH 里找到 Edge：%%P
    start "" "%%P" "%FILE_URL%"
    goto end_ok
  )
)

rem --- 2.3 用 PowerShell Get-Command msedge ---
echo  [3/5] 🔍 PowerShell 探测 msedge 命令...
for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p = $null; try { $c = Get-Command msedge -ErrorAction Stop; $p = $c.Source } catch {}; if (-not $p) { try { $c = Get-Command msedge.exe -ErrorAction Stop; $p = $c.Source } catch {} }; if ($p) { Write-Output $p }" 2^>nul`) do (
  if exist "%%P" (
    echo  [4/5] ✅ PowerShell Get-Command 找到：%%P
    start "" "%%P" "%FILE_URL%"
    goto end_ok
  )
)

rem --- 2.4 用「microsoft-edge:」协议（Windows 10+ 自带，只要装过 Edge 就一定注册了） ---
echo  [4/5] 🔗 尝试 microsoft-edge: 协议（Windows 10+ 内置）...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u = $env:FILE_URL;" ^
  "$proto = 'microsoft-edge:' + $u;" ^
  "Write-Host '       → 调用协议地址：' $proto;" ^
  "Start-Process -FilePath $proto -ErrorAction Stop;"
if not errorlevel 1 goto end_ok

rem --- 2.5 最简 start msedge.exe ---
echo  [5/5] 🎯 最后尝试：start msedge.exe ...
start "" msedge.exe "%FILE_URL%" 2>nul
if not errorlevel 1 goto end_ok

rem ========== 终极兜底：所有方式都失败 → 告诉你电脑上没装 Edge，提供下载链接，绝不开联想浏览器 ==========
echo.
echo  ================================================================
echo   ❌  没在你的电脑上找到 Microsoft Edge，无法启动。
echo       【本脚本已经强制禁止回退到系统默认浏览器】，
echo       这样就不会出现「用双击后默认跳到联想浏览器/360浏览器」导致数据丢失的问题。
echo  ================================================================
echo.
echo   解决方案（任选其一，30 秒搞定）：
echo.
echo     ① 下载安装 Microsoft Edge（免费官方）：
echo        https://www.microsoft.com/edge
echo        安装完成后再双击本脚本一次。
echo.
echo     ② 如果你已经装了 Edge 但脚本没找到：
echo        手动打开 Edge，把下面这段【完整地址】复制粘贴到地址栏回车即可：
echo.
echo        %FILE_URL%
echo.
echo        （建议：打开后收藏到 Edge 收藏夹，下次直接从收藏夹进）
echo.
pause
endlocal
exit /b 1

:end_ok
echo.
echo  ✅ App 已在 Edge 中打开！
echo     如果 5 秒后浏览器没弹出来，请到 Edge 里看「新标签页」。
timeout /t 3 /nobreak >nul
endlocal
exit /b 0
