@echo off

:: Start the local variable
setlocal

:: check the Promot
if defined server_root ( 
    goto :startit
) else (
    echo -------------------------------------------------
    echo Please Only Use MyDevServer Shell.
    echo:
    pause
    echo:
    goto :eof
)

:startit
:: Define remote script URL
set REMOTE_SCRIPT_URL=http://yourserver.com/CustomRepo/scripts/main_script.bat

:: Create Version
IF NOT EXIST %server_root%install MD %server_root%install
IF NOT EXIST %server_root%install\.version (
    echo 1.0.1-alpha >> %server_root%install\.version
)

:: Check Argument
if "%1" equ "clean" (
    call :wcn
) else if "%1" equ "help" (
    call :help %2
) else if "%1" equ "install" (
    call :wcn
) else if "%1" equ "list" (
    call :wcn
) else if "%1" equ "purge" (
    call :wcn
) else if "%1" equ "remove" (
    call :wcn
) else if "%1" equ "search" (
    call :wcn
) else if "%1" equ "setup" (
    call :wcn
) else if "%1" equ "show" (
    call :wcn
) else if "%1" equ "shell" (
    %server_root%shell.bat
) else if "%1" equ "start" (
    call :wcn
) else if "%1" equ "status" (
    call :wcn
) else if "%1" equ "stop" (
    call :wcn
) else if "%1" equ "version" (
    call :version
) else if "%1" equ "update" (
    call :update
) else if "%1" equ "upgrade" (
    call :wcn
) else (
    call :Invalidcmd
)

:: End the local variable
endlocal

goto :eof

:: welcome note
:wcn
    echo ----------------------------------------------
    echo Thanks for Being with us.
    echo This section is still in devolopment.
    echo Please kindly wait for next release.
goto :eof

:: Update the package information
:update
    echo Updating package list...
    
    @REM dir /b /ad %POOL_DIR% > %TMP_DIR%\packages.txt
goto :eof
:: Version Information
:version
    echo ----------------------------------------------
    for /f "" %%x in (%server_root%install\.version) do echo MyDevServer:  %%x
    echo Author: Nazmul Islam Akash 
GOTO :eof
:: Invalid Command 
:Invalidcmd
    echo ----------------------------------------------
    echo Invalid command.
    call :help
goto :eof
:: Help
:help
    if "%~1" neq "" (
        if "%~1" equ "install" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server install [package_name]
            echo:
            echo This command used to install a package. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "clean" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server clean
            echo:
            echo This command used to Clean temporary files and the broken packages which can't be Installed. 
        ) else if "%~1" equ "help" (
            call :help
        ) else if "%~1" equ "list" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server list [command]
            echo:
            echo list                - List all package
            echo list install        - List only Installed package
            echo:
            echo This command used to show list of all or installed packages.
        ) else if "%~1" equ "purge" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server purge [package_name] 
            echo:
            echo This command used to remove a package and it's necessary packages and Folders. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "remove" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server remove [package_name]
            echo:
            echo This command used to remove a package without removing it's necessary packages and Folders. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "search" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server search [package_name] 
            echo:
            echo This command used to search a package. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "setup" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server setup 
            echo:
            echo This command used to Setup MyDevServer for local web base Control Panel. it will autometic install Apache2 and Php server for the control panel.
        ) else if "%~1" equ "show" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server show [package_name]  
            echo:
            echo This command used to Show details of a package and it's help menu. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "shell" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server shell
            echo Usage: shell
            echo:
            echo This command used to clear The Console.
        ) else if "%~1" equ "start" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server start control
            echo        server start [package_name] 
            echo:
            echo This command used to Start MyDevServer for local web base Control Panel or a specific package. it will autometic install and Setup Apache2 and Php server for the control panel if these packages not installed. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "status" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server status [package_name]  
            echo:
            echo This command used to Show Installed Packages status. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "stop" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server stop control           - Stop the control Panel
            echo        server stop [package_name]    - Stop the package
            echo:
            echo This command used to Stop MyDevServer for local web base Control Panel or a specific package. The [package_name] should be replace with the desired package name.
        ) else if "%~1" equ "version" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server version  
            echo:
            echo This command used to Show MyDevServer version and author.
        ) else if "%~1" equ "update" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server update 
            echo:
            echo This command used to Update the package list.
        ) else if "%~1" equ "upgrade" (
            echo ----------------------------------------------
            echo MyDevServer Package Manager Help Menu
            echo:
            echo Usage: server upgrade all              - Upgrade all packages
            echo        server upgrade installed        - Show the list of packages can be upgrade
            echo        server upgrade [package_name]   - Upgrade specific package  
            echo:
            echo This command used to Update an existing package or Upgrade all packages. The [package_name] should be replace with the desired package name.
        ) else (
            call :Invalidcmd
        )
    ) else (
        echo ----------------------------------------------
        echo MyDevServer Package Manager Help Menu
        echo:
        echo Usage: server [options]
        echo:
        @REM echo add [package]          - Add a new package
        echo clean                  - Clean temporary files
        echo help                   - Display this help menu
        echo install [package]      - Install a package
        echo list [command]         - List all packages
        echo purge [package]        - Purge a package
        echo remove [package]       - Remove a package
        echo search [package]       - Search for a package
        echo setup                  - Setup MyDevServer for local web base Control Panel
        echo show [package]         - Show details of a package
        echo shell                  - clear The Console
        echo start [package]        - Start the local server control panel or any server package
        echo status [package]       - Installed Packages status
        echo stop [package]         - Stop all servers or any package server
        echo version                - Show MyDevServer version 
        echo update                 - Update the package list
        echo upgrade [package]      - Update an existing package or Upgrade all packages
        echo:
        echo For more information on a specific command, type server help [command-name] 
    )
goto :eof
