@echo off

:: Check if the OS is 64-bit
if defined ProgramFiles(x86) (
    goto :checkterminal
) else (
    echo This PC is running a 32-bit operating system.
    echo We are really sorry we don't support any 32-bit operating system.
    timeout /t 10
    exit 1
)
:checkterminal
    :: check Root Variable
    if defined server_root (
        goto :shellup
    ) else (
        goto :IsAdmin
    )
:shellup
    if "%~1" equ "update" (
        echo updating Shell
        call :environment
    ) else (
        echo Invalid Command.
        exit /b
        )
goto :eof
:IsAdmin
    openfiles 1>nul 2>&1
    if %errorlevel% neq 0 (
        echo Requesting Administrator privileges...
        goto :UACPrompt
    ) else (
        if "%~1" equ "setenv" (
            echo.
            echo Welcome To MyDevServer.
            echo Setting up the environment for Server shell for Windows.
            call :environment
            echo --------------------------------------------------------------
            echo.
        ) else (
            prompt %username%@%computername%$S$G$S$P$S$S$S$S$S$S$S$D$S$T$_#$G$S >nul
            Start "MyDevServer for Windows" %COMSPEC% /k "%~f0" setenv
        )
    )
goto :eof

:environment
    :: Define Root Path
    set "SERVER_ROOT=%~dp0"
    set "SERVER_BIN_DIR=%~dp0bin\"
    set "SERVER_TMP=%~dp0tmp\"
    set "SERVER_POOL=%~dp0pool\"
    set "PACKAGES_PATH=%~dp0scripts\"
    :: Check Root Folders
    if not exist %SERVER_BIN_DIR% md %SERVER_BIN_DIR%
    if not exist %SERVER_TMP% md %SERVER_TMP%
    if not exist %SERVER_POOL% md %SERVER_POOL%
    if not exist %PACKAGES_PATH% md %PACKAGES_PATH%
    :: Check Base Dependencies
    if not exist "%SERVER_BIN_DIR%server.bat" (
        echo The System Couldn't find Server.bat.
        echo Server.bat is required.
        timeout /t 10
        exit 1
    )
    if not exist "%SERVER_BIN_DIR%curl.exe" (
        echo The System Couldn't find Curl.
        timeout /t 10
        exit 1
    ) else (
        "%SERVER_BIN_DIR%curl.exe" -V > "%SERVER_TMP%curl.test.tmp"
        if %ERRORLEVEL% neq 0 (
            echo There is a problem in The Curl. 
            timeout /t 10
            exit /b
        )
    )
    if not exist "%SERVER_BIN_DIR%tar.exe" (
        echo The System Couldn't find Tar.
        timeout /t 10
        exit 1
    ) else (
        "%SERVER_BIN_DIR%tar.exe" --version > "%SERVER_TMP%tar.test.tmp"
        if %ERRORLEVEL% neq 0 (
            echo There is a problem in The Tar. 
            timeout /t 10
            exit /b
        )
    )
    :: Check package files
    if exist "%SERVER_POOL%package.list" (
        call :filecheck
    ) else (
        call :emptyfile
    )
    :: include bin dir
    if exist "%SERVER_POOL%package.bin.list" (
        for /f "tokens=2 delims= " %%a in (%SERVER_POOL%package.bin.list) do (
            if "%%a" neq "%SERVER_BIN_DIR%" (
                for /f "tokens=* delims=;" %%b in ("%PACKAGES_PATH%") do (
                    echo %%b | findstr %%a > nul
                    if not ERRORLEVEL 1 (
                        @REM echo %%a
                    ) else (
                        set "PACKAGES_PATH=%PACKAGES_PATH%;%%a"
                    )
                    
                )
            )
        )
    )
    if exist %SERVER_TMP%temp_package.list del %SERVER_TMP%temp_package.list
    if exist "%SERVER_TMP%curl.test.tmp" del "%SERVER_TMP%curl.test.tmp"
    if exist "%SERVER_TMP%tar.test.tmp" del "%SERVER_TMP%tar.test.tmp"
    if exist "%SERVER_TMP%temp_path.tmp" del "%SERVER_TMP%temp_path.tmp"
    :: Define the path 
    for %%A in ("%PATH:;=" "%") do (
        echo %%~A >> "%SERVER_TMP%temp_path.tmp"
    )
    CALL :newpath
    if exist "%SERVER_TMP%temp_path.tmp" del "%SERVER_TMP%temp_path.tmp"
    exit /b 0

goto :eof
:: Functions
:: check for path
:newpath
    find /i "%SERVER_ROOT%" "%SERVER_TMP%temp_path.tmp" >nul
    if %ERRORLEVEL% neq 0 (
        SET "PATH=%SERVER_ROOT%;%SERVER_BIN_DIR%;%PACKAGES_PATH%;%PATH%"
    ) else (
        call :ncp
    )
goto :eof
:ncp
    find /i "%SERVER_BIN_DIR%" "%SERVER_TMP%temp_path.tmp" >nul
    if %ERRORLEVEL% neq 0 (
        SET "PATH=%SERVER_BIN_DIR%;%PACKAGES_PATH%;%PATH%"
    ) else (
        call :ncpa
    )
goto :eof
:ncpa
    for %%a in (%PACKAGES_PATH%) do (
        find /i "%%a" "%SERVER_TMP%temp_path.tmp" >nul
        call :ncpb %%a
    )
goto :eof
:ncpb
    if %ERRORLEVEL% neq 0 (
        SET "PATH=%~1;%PATH%"
    ) 
goto :eof
:: Check package file // Old Install
:filecheck
    findstr /c:"[BASE]" %SERVER_POOL%package.list > nul
    if %ERRORLEVEL% EQU 0 (
        call :fcok
    ) else (
        echo %SERVER_POOL%package.list has an error.
        echo [BASE] not Found.
        timeout /t 20 
        exit
    )
goto :eof
:: If the Package list is ok
:fcok
    findstr /c:"[/BASE]" %SERVER_POOL%package.list > nul
    if %ERRORLEVEL% equ 0 (
        call :fcsia
    ) else (
        echo %SERVER_POOL%package.list has an error.
        echo [/BASE] not Found.
        timeout /t 20 
        exit
    )
goto :eof
:: Check for [INSTALLED]
:fcsia
    findstr /c:"[INSTALLED]" %SERVER_POOL%package.list > nul
    if %ERRORLEVEL% equ 0 (
        call :fceia
    ) else (
        echo %SERVER_POOL%package.list has an error.
        echo [INSTALLED] not Found.
        timeout /t 20 
        exit
    )
goto :eof
:: Check for [INSTALLED]
:fceia
    findstr /c:"[/INSTALLED]" %SERVER_POOL%package.list > nul
    if %ERRORLEVEL% equ 0 (
        call :cln
    ) else (
        echo %SERVER_POOL%package.list has an error.
        echo [/INSTALLED] not Found.
        timeout /t 20 
        exit
    )
goto :eof
:: Check for curl
:cln
    findstr /c:"Curl" %SERVER_POOL%package.list > nul
    if %ERRORLEVEL% equ 0 (
        call :clne
    ) else (
        call :pec
    )
goto :eof
:: Check for tar
:clne
    findstr /c:"Tar" %SERVER_POOL%package.list > nul
    IF %ERRORLEVEL% EQU 0 (
        call :clnee
    ) ELSE (
        call :pec
    )
goto :eof
:: Check for base /base line number
:clnee
    for /f "tokens=1 delims=:" %%a in ( ' findstr /n /c:"[BASE]" %SERVER_POOL%package.list ' ) do (
        for /f "tokens=1 delims=:" %%b in ( ' findstr /n /c:"[/BASE]" %SERVER_POOL%package.list ' ) do (
            call :cct %%a %%b
        )
    )
goto :eof
:: Check Base Packages line number
:cct
    for /f "tokens=1 delims=:" %%a in ( ' findstr /n /c:"Curl" %SERVER_POOL%package.list ' ) do (
        for /f "tokens=1 delims=:" %%b in ( ' findstr /n /c:"Tar" %SERVER_POOL%package.list ' ) do (
            call :cbp %%a %%b %~1 %~2
        )
    )
goto :eof
:: check base package exist in base area
:cbp 
    :: for curl
    if %~1 gtr %~3 (
        if %~1 lss %~4 (
            goto cbpt
        ) else (
            call :pecc "Curl" %~1 %~2 %~3 %~4
        )
    ) else (
        call :pecc "Curl" %~1 %~2 %~3 %~4
    )
    :: for Tar 
    :cbpt
    if %~2 gtr %~3 (
        if %~2 lss %~4 (
            goto cbpe
        ) else (
            call :pecc "Tar" %~1 %~2 %~3 %~4
        )
    ) else (
        call :pecc "Tar" %~1 %~2 %~3 %~4
    )
    :cbpe
    findstr /c:"Curl" %SERVER_POOL%package.bin.list > nul
    if %ERRORLEVEL% EQU 0 (
        call :cpbet
    ) else (
        call :efbcheck "Curl"
        goto :cbpe
    )
    :cbpes
    for /f "tokens=1 delims= " %%a in ( ' findstr /c:"Curl" %SERVER_POOL%package.bin.list ' ) do (
        for /f "tokens=2 delims= " %%b in ( ' findstr /c:"Curl" %SERVER_POOL%package.bin.list ' ) do (
            call :cbbl %%a %%b
        )
    )
    for /f "tokens=1 delims= " %%a in ( ' findstr /c:"Tar" %SERVER_POOL%package.bin.list ' ) do (
        for /f "tokens=2 delims= " %%b in ( ' findstr /c:"Tar" %SERVER_POOL%package.bin.list ' ) do (
            call :cbbl %%a %%b
        )
    )
goto :eof
:: check tar
:cpbet
    findstr /c:"Tar" %SERVER_POOL%package.bin.list > nul
    if %ERRORLEVEL% equ 0 (
        goto :cbpes
    ) else (
        call :efbcheck "Tar"
        goto :cbpe
    )
goto :eof
:: Check Base Package BIn list
:cbbl
    if exist %SERVER_TMP%temp_package.bin.list del %SERVER_TMP%temp_package.bin.list
    if %~2 neq %SERVER_BIN_DIR% (
        for /f "tokens=*" %%c in (%SERVER_POOL%package.bin.list) do (
            echo %%c | findstr /c:"%~1" > nul
            if not ERRORLEVEL 1 goto :done
            echo %%c >> %SERVER_TMP%temp_package.bin.list
        )
    ) else (
        goto :eof
    )
    :done
    for /r "%SERVER_ROOT%" %%b in (*%~1.exe) do (
        echo %~1 %%~dpb >> %SERVER_TMP%temp_package.bin.list
    )
    for /f "tokens=*" %%c in (%SERVER_POOL%package.bin.list) do (
        echo %%c | findstr /c:"%~1" > nul
        if not ERRORLEVEL 1 (
            for /f "tokens=1 delims=:" %%a in (' findstr /N /c:"%~1" %SERVER_POOL%package.bin.list ') do (
                for /f "tokens=*" %%b in (' more +%%a %SERVER_POOL%package.bin.list ') do (
                    echo %%b >> %SERVER_TMP%temp_package.bin.list
                )
            )
            goto :next
        )
    )
    :next
    move %SERVER_TMP%temp_package.bin.list %SERVER_POOL%package.bin.list > nul
    if exist %SERVER_TMP%temp_package.bin.list del %SERVER_TMP%temp_package.bin.list
goto :eof
:: recreate pack
:pec
    if exist %SERVER_TMP%temp_package.list del %SERVER_TMP%temp_package.list
    for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
            echo %%c | findstr /c:"[BASE]" > nul
            if not ERRORLEVEL 1 ( 
                echo [BASE] >> %SERVER_TMP%temp_package.list
                goto :donet
            )
            echo %%c >> %SERVER_TMP%temp_package.list
    )
    :donet
    for /f "tokens=2 delims= " %%V in ( ' findstr /i "curl" "%SERVER_TMP%curl.test.tmp"' ) do (
            echo Curl %%V >> %SERVER_TMP%temp_package.list
    )
    for /f "tokens=4 delims= " %%V in ( ' findstr /i "tar" "%SERVER_TMP%tar.test.tmp"' ) do (
        echo Tar %%V >> %SERVER_TMP%temp_package.list
    )
    echo [/BASE] >> %SERVER_TMP%temp_package.list
    for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
        echo %%c | findstr /c:"[/BASE]" > nul
        if not ERRORLEVEL 1 (
            for /f "tokens=1 delims=:" %%a in (' findstr /n /c:"[/BASE]" %SERVER_POOL%package.list ') do (
                for /f "tokens=*" %%b in (' more +%%a %SERVER_POOL%package.list ') do (
                    echo %%b >> %SERVER_TMP%temp_package.list
                )
            )
            goto :nextt
        )
    )
    :nextt
    move %SERVER_TMP%temp_package.list %SERVER_POOL%package.list > nul
goto :eof
:pecc
    if exist %SERVER_TMP%temp_package.list del %SERVER_TMP%temp_package.list
    if "%~1" equ "Curl" if %~2 lss %~4 (
        for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
            echo %%c | findstr /c:"%~1" > nul
            if not ERRORLEVEL 1 ( 
                goto :donett
            )
            echo %%c >> %SERVER_TMP%temp_package.list
        )
    )
    if "%~1" equ "Curl" if %~2 gtr %~5 (
        for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
            echo %%c | findstr /c:"[BASE]" > nul
            if not ERRORLEVEL 1 ( 
                echo [BASE] >> %SERVER_TMP%temp_package.list
                call :donettt
                goto :donettttt
            )
            echo %%c >> %SERVER_TMP%temp_package.list
        )
    )
    if "%~1" equ "Tar" if %~3 LSS %~4 (
        for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
            echo %%c | findstr /c:"%~1" > nul
            if not ERRORLEVEL 1 ( 
                goto :donett
            )
            echo %%c >> %SERVER_TMP%temp_package.list
        )
    )
    if "%~1" equ "Tar" if %~3 gtr %~5 (
        for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
            echo %%c | findstr /c:"[BASE]" > nul
            if not ERRORLEVEL 1 ( 
                echo [BASE] >> %SERVER_TMP%temp_package.list
                call :donettt
                goto :donettttt
            )
            echo %%c >> %SERVER_TMP%temp_package.list
        )
    )
    :donett
    if "%~1" equ "Curl" (
        for /f "tokens=*" %%b in (' more +%~2 %SERVER_POOL%package.list ') do (
            echo %%b | findstr /c:"[BASE]" > nul 
            if not ERRORLEVEL 1 (
                ECHO [BASE] >> %SERVER_TMP%temp_package.list
                call :donettt
                goto :donetttt
            )
            echo %%b >> %SERVER_TMP%temp_package.list
        )
    )
    if "%~1" equ "Tar" (
        for /f "tokens=*" %%b in (' more +%~3 %SERVER_POOL%package.list ') do (
            echo %%b | findstr /c:"[BASE]" > nul 
            if not ERRORLEVEL 1 (
                echo [BASE] >> %SERVER_TMP%temp_package.list
                call :donettt
                goto :donetttt
            )
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
    )
    :donetttt
    for /f "tokens=*" %%c in (%SERVER_POOL%package.list) do (
        echo %%c | findstr /c:"[/BASE]" > nul
        if not ERRORLEVEL 1 (
            for /f "tokens=1 delims=:" %%a in (' findstr /N /c:"[/BASE]" %SERVER_POOL%package.list ') do (
                for /f "tokens=*" %%b in (' more +%%a %SERVER_POOL%package.list ') do (
                    echo %%b >> %SERVER_TMP%temp_package.list
                )
            )
            goto :nextt
        )
    )
    :donettttt
    if "%~1" equ "Curl" (
        for /f "tokens=*" %%b in (' more +%~5 %SERVER_POOL%package.list ') do (
            echo %%b | findstr /c:"%~1" > nul
            if not ERRORLEVEL 1 (
                goto :donetttttt
            )
            echo %%b >> %SERVER_TMP%temp_package.list
        )
    )
    if "%~1" equ "Tar" (
        for /f "tokens=*" %%b in (' more +%~5 %SERVER_POOL%package.list ') do (
            echo %%b | findstr /c:"%~1" > nul
            if not ERRORLEVEL 1 (
                goto :donetttttt
            )
            echo %%b >> %SERVER_TMP%temp_package.list
        )
    )
    :donetttttt
    if "%~1" equ "Curl" (
        for /f "tokens=*" %%b in (' more +%~2 %SERVER_POOL%package.list ') do (
            echo %%b >> %SERVER_TMP%temp_package.list
        )
        goto :nextt
    )
    if "%~1" equ "Tar" (
        for /f "tokens=*" %%b in (' more +%~3 %SERVER_POOL%package.list ') do (
            echo %%b >> %SERVER_TMP%temp_package.list
        )
        goto :nextt
    )
    :nextt
    move %SERVER_TMP%temp_package.list %SERVER_POOL%package.list > nul
goto :eof
:donettt
    for /f "tokens=2 delims= " %%V in ( ' findstr /i "curl" "%SERVER_TMP%curl.test.tmp"' ) do (
            echo Curl %%V >> %SERVER_TMP%temp_package.list
    )
    for /f "tokens=4 delims= " %%V in ( ' findstr /i "tar" "%SERVER_TMP%tar.test.tmp"' ) do (
        echo Tar %%V >> %SERVER_TMP%temp_package.list
    )
    echo [/BASE] >> %SERVER_TMP%temp_package.list
goto :eof
:emptyfile
    :: If New Install
    echo [BASE] >> %SERVER_POOL%package.list
    for /f "tokens=2 delims= " %%v in ( 'findstr /i "curl" "%SERVER_TMP%curl.test.tmp"' ) do (
        echo Curl %%v >> "%SERVER_POOL%package.list"
    )
    for /f "tokens=4 delims= " %%v in ( 'findstr /i "tar" "%SERVER_TMP%tar.test.tmp"' ) do (
        echo Tar %%v >> %SERVER_POOL%package.list
    )
    echo [/BASE] >> %SERVER_POOL%package.list
    echo [INSTALLED] >> %SERVER_POOL%package.list
    echo [/INSTALLED] >> %SERVER_POOL%package.list
    call :emptyfilebin
goto :eof
:: Empty file bin
:emptyfilebin
    for /f "tokens=*" %%a in (%SERVER_POOL%package.list) do (
        call :efbcheck %%a
    )
goto :eof
:: Empty file path write
:efbcheck
    if "%~1" neq "[BASE]" if "%~1" neq "[/BASE]" (
        for /r "%SERVER_ROOT%" %%b in (*%~1.exe) do (
            echo %~1 %%~dpb >> %SERVER_POOL%package.bin.list
        )
    )
goto :eof
:UACPrompt
    :: Prompt for Administrator privileges using VBScript
    echo Set objShell = CreateObject("Shell.Application") > "%temp%\GetAdmin.vbs"
    echo objShell.ShellExecute "%COMSPEC%", "/c cd /d %cd% && %~f0 ", "", "runas", 1 >> "%temp%\GetAdmin.vbs"
    cscript "%temp%\GetAdmin.vbs"
    del "%temp%\GetAdmin.vbs"
    exit /b
