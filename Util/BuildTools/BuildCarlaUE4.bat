@echo off
setlocal enabledelayedexpansion

rem BAT script that creates the binaries for Carla (carla.org).
rem Run it through a cmd with the x64 Visual C++ Toolset enabled.

set LOCAL_PATH=%~dp0
set "FILE_N=-[%~n0]:"

rem Print batch params (debug purpose)
echo %FILE_N% [Batch params]: %*

rem ============================================================================
rem -- Parse arguments ---------------------------------------------------------
rem ============================================================================

set BUILD_UE4_EDITOR=false
set LAUNCH_UE4_EDITOR=false
set REMOVE_INTERMEDIATE=false

:arg-parse
echo %1
if not "%1"=="" (
    if "%1"=="--build" (
        set BUILD_UE4_EDITOR=true
    )
    if "%1"=="--launch" (
        set LAUNCH_UE4_EDITOR=true
    )
    if "%1"=="--clean" (
        set REMOVE_INTERMEDIATE=true
    )
    if "%1"=="-h" (
        goto help
    )
    if "%1"=="--help" (
        goto help
    )
    shift
    goto arg-parse
)

if %REMOVE_INTERMEDIATE% == false (
    if %LAUNCH_UE4_EDITOR% == false (
        if %BUILD_UE4_EDITOR% == false (
            echo Nothing selected to be done.
            echo %USAGE_STRING%
            goto eof
        )
    )
)

rem Get Unreal Engine root path
if not defined UE4_ROOT (
    set KEY_NAME="HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine"
    set VALUE_NAME=InstalledDirectory
    for /f "usebackq tokens=1,2,*" %%A in (`reg query !KEY_NAME! /s /reg:64`) do (
        if "%%A" == "!VALUE_NAME!" (
            set UE4_ROOT=%%C
        )
    )
    if not defined UE4_ROOT goto error_unreal_no_found
)

rem Set the visual studio solution directory
rem
set UE4_PROJECT_FOLDER=%ROOT_PATH%Unreal\CarlaUE4\
pushd "%UE4_PROJECT_FOLDER%"

rem Clear binaries and intermediates generated by the build system
rem
if %REMOVE_INTERMEDIATE% == true (
    rem Remove directories
    for %%G in (
        "%UE4_PROJECT_FOLDER:/=\%Binaries",
        "%UE4_PROJECT_FOLDER:/=\%Build",
        "%UE4_PROJECT_FOLDER:/=\%Saved",
        "%UE4_PROJECT_FOLDER:/=\%Intermediate",
        "%UE4_PROJECT_FOLDER:/=\%Plugins\Carla\Binaries",
        "%UE4_PROJECT_FOLDER:/=\%Plugins\Carla\Intermediate",
        "%UE4_PROJECT_FOLDER:/=\%.vs"
    ) do (
        if exist %%G (
            echo %FILE_N% Cleaning %%G
            rmdir /s/q %%G
        )
    )

    rem Remove files
    for %%G in (
        "%UE4_PROJECT_FOLDER:/=\%CarlaUE4.sln"
    ) do (
        if exist %%G (
            echo %FILE_N% Cleaning %%G
            del %%G
        )
    )
)

rem Build Carla Editor
rem
if %BUILD_UE4_EDITOR% == true (
    echo %FILE_N% Building Unreal Editor...

    call "%UE4_ROOT%\Engine\Build\BatchFiles\Build.bat"^
        CarlaUE4Editor^
        Win64^
        Development^
        -WaitMutex^
        -FromMsBuild^
        "%ROOT_PATH%Unreal/CarlaUE4/CarlaUE4.uproject"
    if errorlevel 1 goto bad_exit

    call "%UE4_ROOT%\Engine\Build\BatchFiles\Build.bat"^
        CarlaUE4^
        Win64^
        Development^
        -WaitMutex^
        -FromMsBuild^
        "%ROOT_PATH%Unreal/CarlaUE4/CarlaUE4.uproject"
    if errorlevel 1 goto bad_exit
)

rem Launch Carla Editor
rem
if %LAUNCH_UE4_EDITOR% == true (
    echo %FILE_N% Launching Unreal Editor...
    call "%UE4_PROJECT_FOLDER%CarlaUE4.uproject"
    if %errorlevel% neq 0 goto error_build
)

goto good_exit

rem ============================================================================
rem -- Messages and Errors -----------------------------------------------------
rem ============================================================================

:help
    echo Build LibCarla.
    echo "Usage: %FILE_N% [-h^|--help] [--build] [--launch] [--clean]"
    goto good_exit

:error_build
    echo.
    echo %FILE_N% [ERROR] There was a problem building CarlaUE4.
    echo %FILE_N%         Please go to "Carla\Unreal\CarlaUE4", right click on
    echo %FILE_N%         "CarlaUE4.uproject" and select:
    echo %FILE_N%         "Generate Visual Studio project files"
    echo %FILE_N%         Open de generated "CarlaUE4.sln" and try to manually compile it
    echo %FILE_N%         and check what is causing the error.
    goto bad_exit

:good_exit
    endlocal
    exit /b 0

:bad_exit
    endlocal
    exit /b %errorlevel%

:error_unreal_no_found
    echo.
    echo %FILE_N% [ERROR] Unreal Engine not detected
    goto bad_exit
