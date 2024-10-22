@ECHO OFF

:: Check to Start the Command Promot
IF "%1" EQU "setenv" (
    ECHO:
    ECHO Welcome To MyDevServer
    ECHO Setting up the environment for Server shell for Windows.
    CALL :environment
    ECHO --------------------------------------------------------------
    GOTO :EOF
) ELSE (
    IF DEFINED SERVER_ROOT ( 
        ENDLOCAL
        CLS
        ECHO:
        ECHO Welcome To MyDevServer
        ECHO Setting up the environment for Server shell for Windows.
        ECHO --------------------------------------------------------------
        @REM GOTO bindir
    ) ELSE (
        SETLOCAL
        PROMPT %username%@%computername%$S$G$S$P$S$S$S$S$S$S$S$D$S$T$_#$G$S
        START "MyDevServer for Windows" %COMSPEC% /k "%~f0" setenv
        ENDLOCAL
    )
    GOTO :EOF
)

:: Setting up the Environment variables
:environment
    :: Define Root Path
    SET "SERVER_ROOT=%~dp0"
    SET "SERVER_BIN_DIR=%~dp0bin\"
    SET "SERVER_TMP=%~dp0tmp\"
    SET "SERVER_POOL=%~dp0pool\"
    SET "PACKAGES_PATH=%~dp0scripts\"

    :: Check Root Folders
    IF NOT EXIST %SERVER_BIN_DIR% MD %SERVER_BIN_DIR%
    IF NOT EXIST %SERVER_TMP% MD %SERVER_TMP%
    IF NOT EXIST %SERVER_POOL% MD %SERVER_POOL%
    IF NOT EXIST %PACKAGES_PATH% MD %PACKAGES_PATH%

    :: Check Base Dependencies
    IF NOT EXIST "%SERVER_BIN_DIR%server.bat" (
        ECHO The System Couldn't find Server.bat.
        ECHO Server.bat is required.
        TIMEOUT /T 20
        EXIT 1
    )

    IF NOT EXIST "%SERVER_BIN_DIR%curl.exe" (
        ECHO The System Couldn't find Curl.
        TIMEOUT /T 20
        EXIT 1
    ) ELSE (
        "%SERVER_BIN_DIR%curl.exe" -V > "%SERVER_TMP%curl.test.tmp"
        IF %ERRORLEVEL% NEQ 0 (
            ECHO %ERRORLEVEL%
            ECHO There is a problem in The Curl. 
            TIMEOUT /T 20
        )
    )
    IF NOT EXIST "%SERVER_BIN_DIR%tar.exe" (
        ECHO The System Couldn't find Tar.
        TIMEOUT /T 20
        EXIT 1
    ) ELSE (
        "%SERVER_BIN_DIR%tar.exe" --version > "%SERVER_TMP%tar.test.tmp"
        IF %ERRORLEVEL% NEQ 0 (
            ECHO %ERRORLEVEL%
            ECHO There is a problem in The Tar. 
            TIMEOUT /T 20
        )
    )
    :: Check package files
    IF EXIST "%SERVER_POOL%package.list" (
        CALL :filecheck
    ) ELSE (
        CALL :emptyfile
    )
    :: include bin dir
    IF EXIST "%SERVER_POOL%package.bin.list" (
        FOR /F "tokens=2 delims= " %%a IN (%SERVER_POOL%package.bin.list) DO (
            IF "%%a" NEQ "%SERVER_BIN_DIR%" (
                FOR /F "tokens=* delims=;" %%b IN ("%PACKAGES_PATH%") DO (
                    ECHO %%b | FINDSTR %%a > NUL
                    IF not ERRORLEVEL 1 (
                        @REM echo %%a
                    ) ELSE (
                        SET "PACKAGES_PATH=%PACKAGES_PATH%;%%a"
                    )
                    
                )
            )
        )
    )
    If EXIST %SERVER_TMP%temp_package.list DEL %SERVER_TMP%temp_package.list
    IF EXIST "%SERVER_TMP%curl.test.tmp" DEL "%SERVER_TMP%curl.test.tmp"
    IF EXIST "%SERVER_TMP%tar.test.tmp" DEL "%SERVER_TMP%tar.test.tmp"

    :: Define the path 
    SET "PATH=;%SERVER_ROOT%;%SERVER_BIN_DIR%;%PACKAGES_PATH%;%PATH%"

GOTO :EOF

:: Empty base package // New Install
:emptyfile
    SETLOCAL
    ECHO [BASE] >> %SERVER_POOL%package.list
    FOR /F "tokens=2 delims= " %%V IN ( 'findstr /i "curl" "%SERVER_TMP%curl.test.tmp"' ) DO (
        ECHO Curl %%V >> "%SERVER_POOL%package.list"
    )
    FOR /F "tokens=4 delims= " %%V IN ( 'findstr /i "tar" "%SERVER_TMP%tar.test.tmp"' ) DO (
        ECHO Tar %%V >> %SERVER_POOL%package.list
    )
    ECHO [/BASE] >> %SERVER_POOL%package.list
    ECHO [INSTALLED] >> %SERVER_POOL%package.list
    ECHO [/INSTALLED] >> %SERVER_POOL%package.list
    CALL :emptyfilebin
    ENDLOCAL
GOTO :EOF
:: Empty file bin
:emptyfilebin
    FOR /F "tokens=*" %%a IN (%SERVER_POOL%package.list) DO (
        CALL :efbcheck %%a
    )
GOTO :EOF
:: Empty file path write
:efbcheck
    IF "%~1" NEQ "[BASE]" IF "%~1" NEQ "[/BASE]" (
        FOR /R "%SERVER_ROOT%" %%b IN (*%~1.exe) DO (
            echo %~1 %%~dpb >> %SERVER_POOL%package.bin.list
        )
    )
GOTO :EOF
:: Check package file // Old Install
:filecheck
    FINDSTR /c:"[BASE]" %SERVER_POOL%package.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :fcok
    ) ELSE (
        ECHO %SERVER_POOL%package.list has an error.
        ECHO [BASE] not Found.
        TIMEOUT /T 20 
        EXIT
    )
GOTO :EOF
:: If the Package list is ok
:fcok
    FINDSTR /c:"[/BASE]" %SERVER_POOL%package.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :fcsia
    ) ELSE (
        ECHO %SERVER_POOL%package.list has an error.
        ECHO [/BASE] not Found.
        TIMEOUT /T 20 
        EXIT
    )
GOTO :EOF
:: Check for curl
:cln
    FINDSTR /c:"Curl" %SERVER_POOL%package.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :clne
    ) ELSE (
        CALL :pec
    )
GOTO :EOF
:: Check for tar
:clne
    FINDSTR /c:"Tar" %SERVER_POOL%package.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :clnee
    ) ELSE (
        CALL :pec
    )
GOTO :EOF
:: recreate pack
:pec
    If EXIST %SERVER_TMP%temp_package.list DEL %SERVER_TMP%temp_package.list
    FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
            ECHO %%c | FINDSTR /c:"[BASE]" > NUL
            IF not ERRORLEVEL 1 ( 
                ECHO [BASE] >> %SERVER_TMP%temp_package.list
                GOTO :donet
            )
            ECHO %%c >> %SERVER_TMP%temp_package.list
    )
    :donet
    FOR /F "tokens=2 delims= " %%V IN ( ' findstr /i "curl" "%SERVER_TMP%curl.test.tmp"' ) DO (
            ECHO Curl %%V >> %SERVER_TMP%temp_package.list
    )
    FOR /F "tokens=4 delims= " %%V IN ( ' findstr /i "tar" "%SERVER_TMP%tar.test.tmp"' ) DO (
        ECHO Tar %%V >> %SERVER_TMP%temp_package.list
    )
    ECHO [/BASE] >> %SERVER_TMP%temp_package.list
    FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
        ECHO %%c | FINDSTR /c:"[/BASE]" > NUL
        IF not ERRORLEVEL 1 (
            FOR /F "tokens=1 delims=:" %%a IN (' FINDSTR /N /c:"[/BASE]" %SERVER_POOL%package.list ') DO (
                FOR /F "tokens=*" %%b IN (' MORE +%%a %SERVER_POOL%package.list ') DO (
                    ECHO %%b >> %SERVER_TMP%temp_package.list
                )
            )
            GOTO :nextt
        )
    )
    :nextt
    MOVE %SERVER_TMP%temp_package.list %SERVER_POOL%package.list > NUL
GOTO :EOF
:pecc
    If EXIST %SERVER_TMP%temp_package.list DEL %SERVER_TMP%temp_package.list
    IF "%~1" EQU "Curl" IF %~2 LSS %~4 (
        FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
            ECHO %%c | FINDSTR /c:"%~1" > NUL
            IF not ERRORLEVEL 1 ( 
                GOTO :donett
            )
            ECHO %%c >> %SERVER_TMP%temp_package.list
        )
    )
    IF "%~1" EQU "Curl" IF %~2 GTR %~5 (
        FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
            ECHO %%c | FINDSTR /c:"[BASE]" > NUL
            IF not ERRORLEVEL 1 ( 
                ECHO [BASE] >> %SERVER_TMP%temp_package.list
                CALL :donettt
                GOTO :donettttt
            )
            ECHO %%c >> %SERVER_TMP%temp_package.list
        )
    )
    IF "%~1" EQU "Tar" IF %~3 LSS %~4 (
        FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
            ECHO %%c | FINDSTR /c:"%~1" > NUL
            IF not ERRORLEVEL 1 ( 
                GOTO :donett
            )
            ECHO %%c >> %SERVER_TMP%temp_package.list
        )
    )
    IF "%~1" EQU "Tar" IF %~3 GTR %~5 (
        FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
            ECHO %%c | FINDSTR /c:"[BASE]" > NUL
            IF not ERRORLEVEL 1 ( 
                ECHO [BASE] >> %SERVER_TMP%temp_package.list
                CALL :donettt
                GOTO :donettttt
            )
            ECHO %%c >> %SERVER_TMP%temp_package.list
        )
    )
    :donett
    IF "%~1" EQU "Curl" (
        FOR /F "tokens=*" %%b IN (' MORE +%~2 %SERVER_POOL%package.list ') DO (
            ECHO %%b | FINDSTR /c:"[BASE]" > NUL 
            IF not ERRORLEVEL 1 (
                ECHO [BASE] >> %SERVER_TMP%temp_package.list
                CALL :donettt
                GOTO :donetttt
            )
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
    )
    IF "%~1" EQU "Tar" (
        FOR /F "tokens=*" %%b IN (' MORE +%~3 %SERVER_POOL%package.list ') DO (
            ECHO %%b | FINDSTR /c:"[BASE]" > NUL 
            IF not ERRORLEVEL 1 (
                ECHO [BASE] >> %SERVER_TMP%temp_package.list
                CALL :donettt
                GOTO :donetttt
            )
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
    )
    
    :donetttt
    FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.list) DO (
        ECHO %%c | FINDSTR /c:"[/BASE]" > NUL
        IF not ERRORLEVEL 1 (
            FOR /F "tokens=1 delims=:" %%a IN (' FINDSTR /N /c:"[/BASE]" %SERVER_POOL%package.list ') DO (
                FOR /F "tokens=*" %%b IN (' MORE +%%a %SERVER_POOL%package.list ') DO (
                    ECHO %%b >> %SERVER_TMP%temp_package.list
                )
            )
            GOTO :nextt
        )
    )
    :donettttt
    IF "%~1" EQU "Curl" (
        FOR /F "tokens=*" %%b IN (' MORE +%~5 %SERVER_POOL%package.list ') DO (
            ECHO %%b | FINDSTR /c:"%~1" > NUL
            IF not ERRORLEVEL 1 (
                GOTO :donetttttt
            )
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
    )
    IF "%~1" EQU "Tar" (
        FOR /F "tokens=*" %%b IN (' MORE +%~5 %SERVER_POOL%package.list ') DO (
            ECHO %%b | FINDSTR /c:"%~1" > NUL
            IF not ERRORLEVEL 1 (
                GOTO :donetttttt
            )
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
    )
    :donetttttt
    IF "%~1" EQU "Curl" (
        FOR /F "tokens=*" %%b IN (' MORE +%~2 %SERVER_POOL%package.list ') DO (
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
        GOTO :nextt
    )
    IF "%~1" EQU "Tar" (
        FOR /F "tokens=*" %%b IN (' MORE +%~3 %SERVER_POOL%package.list ') DO (
            ECHO %%b >> %SERVER_TMP%temp_package.list
        )
        GOTO :nextt
    )

    :nextt
    MOVE %SERVER_TMP%temp_package.list %SERVER_POOL%package.list > NUL
GOTO :EOF
:donettt
    FOR /F "tokens=2 delims= " %%V IN ( ' findstr /i "curl" "%SERVER_TMP%curl.test.tmp"' ) DO (
            ECHO Curl %%V >> %SERVER_TMP%temp_package.list
    )
    FOR /F "tokens=4 delims= " %%V IN ( ' findstr /i "tar" "%SERVER_TMP%tar.test.tmp"' ) DO (
        ECHO Tar %%V >> %SERVER_TMP%temp_package.list
    )
    ECHO [/BASE] >> %SERVER_TMP%temp_package.list
GOTO :EOF

:: Check for base /base line number
:clnee
    FOR /F "tokens=1 delims=:" %%a IN ( ' FINDSTR /n /c:"[BASE]" %SERVER_POOL%package.list ' ) DO (
        FOR /F "tokens=1 delims=:" %%b IN ( ' FINDSTR /n /c:"[/BASE]" %SERVER_POOL%package.list ' ) DO (
            CALL :cct %%a %%b
        )
    )
GOTO :EOF
:: Check Base Packages line number
:cct
    FOR /F "tokens=1 delims=:" %%a IN ( ' FINDSTR /n /c:"Curl" %SERVER_POOL%package.list ' ) DO (
        FOR /F "tokens=1 delims=:" %%b IN ( ' FINDSTR /n /c:"Tar" %SERVER_POOL%package.list ' ) DO (
            CALL :cbp %%a %%b %~1 %~2
        )
    )
GOTO :EOF
:: check base package exist in base area
:cbp 
    :: for curl
    IF %~1 GTR %~3 (
        IF %~1 LSS %~4 (
            GOTO cbpt
        ) ELSE (
            CALL :pecc "Curl" %~1 %~2 %~3 %~4
        )
    ) ELSE (
        CALL :pecc "Curl" %~1 %~2 %~3 %~4
    )
    :: for Tar 
    :cbpt
    IF %~2 GTR %~3 (
        IF %~2 LSS %~4 (
            GOTO cbpe
        ) ELSE (
            CALL :pecc "Tar" %~1 %~2 %~3 %~4
        )
    ) ELSE (
        CALL :pecc "Tar" %~1 %~2 %~3 %~4
    )
    :cbpe
    FINDSTR /c:"Curl" %SERVER_POOL%package.bin.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :cpbet
    ) ELSE (
        CALL :efbcheck "Curl"
        GOTO :cbpe
    )
    :cbpes
    FOR /F "tokens=1 delims= " %%a IN ( ' FINDSTR /c:"Curl" %SERVER_POOL%package.bin.list ' ) DO (
        FOR /F "tokens=2 delims= " %%b IN ( ' FINDSTR /c:"Curl" %SERVER_POOL%package.bin.list ' ) DO (
            CALL :cbbl %%a %%b
        )
    )
    FOR /F "tokens=1 delims= " %%a IN ( ' FINDSTR /c:"Tar" %SERVER_POOL%package.bin.list ' ) DO (
        FOR /F "tokens=2 delims= " %%b IN ( ' FINDSTR /c:"Tar" %SERVER_POOL%package.bin.list ' ) DO (
            CALL :cbbl %%a %%b
        )
    )
GOTO :EOF
:: check tar
:cpbet
    FINDSTR /c:"Tar" %SERVER_POOL%package.bin.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        GOTO :cbpes
    ) ELSE (
        CALL :efbcheck "Tar"
        GOTO :cbpe
    )
GOTO :EOF
:: Check Base Package BIn list
:cbbl
    If EXIST %SERVER_TMP%temp_package.bin.list DEL %SERVER_TMP%temp_package.bin.list
    IF %~2 NEQ %SERVER_BIN_DIR% (
        FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.bin.list) DO (
            ECHO %%c | FINDSTR /c:"%~1" > NUL
            IF not ERRORLEVEL 1 GOTO :done
            ECHO %%c >> %SERVER_TMP%temp_package.bin.list
        )
    ) ELSE (
        GOTO :EOF
    )
    :done
    FOR /R "%SERVER_ROOT%" %%b IN (*%~1.exe) DO (
        echo %~1 %%~dpb >> %SERVER_TMP%temp_package.bin.list
    )
    FOR /F "tokens=*" %%c IN (%SERVER_POOL%package.bin.list) DO (
        ECHO %%c | FINDSTR /c:"%~1" > NUL
        IF not ERRORLEVEL 1 (
            FOR /F "tokens=1 delims=:" %%a IN (' FINDSTR /N /c:"%~1" %SERVER_POOL%package.bin.list ') DO (
                FOR /F "tokens=*" %%b IN (' MORE +%%a %SERVER_POOL%package.bin.list ') DO (
                    ECHO %%b >> %SERVER_TMP%temp_package.bin.list
                )
            )
            GOTO :next
        )
    )
    :next
    MOVE %SERVER_TMP%temp_package.bin.list %SERVER_POOL%package.bin.list > NUL
    If EXIST %SERVER_TMP%temp_package.bin.list DEL %SERVER_TMP%temp_package.bin.list
GOTO :EOF
:: Check for [INSTALLED]
:fcsia
    FINDSTR /c:"[INSTALLED]" %SERVER_POOL%package.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :fceia
    ) ELSE (
        ECHO %SERVER_POOL%package.list has an error.
        ECHO [INSTALLED] not Found.
        TIMEOUT /T 20 
        EXIT
    )
:: Check for [INSTALLED]
:fceia
    FINDSTR /c:"[/INSTALLED]" %SERVER_POOL%package.list > NUL
    IF %ERRORLEVEL% EQU 0 (
        CALL :cln
    ) ELSE (
        ECHO %SERVER_POOL%package.list has an error.
        ECHO [/INSTALLED] not Found.
        TIMEOUT /T 20 
        EXIT
    )
GOTO :EOF
