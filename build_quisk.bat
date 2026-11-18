@echo off
rem Build the Quisk C extension (_quisk.*.pyd) on Windows with WinLibs MinGW-w64 GCC.
rem Run from a Command Prompt:  build_quisk.bat
rem Requires: C:\mingw64 (WinLibs GCC), 64-bit Python on the PATH, and fftw3.h in this folder.
setlocal
set MINGW=C:\mingw64\bin
set PATH=%MINGW%;%PATH%
cd /d "%~dp0"

set FFTWINC=.
if not exist fftw3.h set FFTWINC=fftw-3.3.5-dll64
if not exist "%FFTWINC%\fftw3.h" (
  echo ERROR: fftw3.h is missing. Put it in this folder or in fftw-3.3.5-dll64.
  exit /b 1
)
echo fftw3.h from:   %FFTWINC%
where gcc >nul 2>nul || (echo ERROR: gcc not found in %MINGW% & exit /b 1)
where python >nul 2>nul || (echo ERROR: python not found on the PATH & exit /b 1)

for /f "delims=" %%i in ('python -c "import sysconfig;print(sysconfig.get_paths()['include'])"') do set PYINC=%%i
for /f "delims=" %%i in ('python -c "import sys;print(sys.base_prefix)"') do set PYBASE=%%i
for /f "delims=" %%i in ('python -c "import sys;print(f'python{sys.version_info[0]}{sys.version_info[1]}')"') do set PYLIB=%%i
for /f "delims=" %%i in ('python -c "import sysconfig;print(sysconfig.get_config_var('EXT_SUFFIX'))"') do set SUFFIX=%%i
for /f "delims=" %%i in ('python -c "import struct;print(struct.calcsize('P')*8)"') do set PYBITS=%%i

echo Python include: %PYINC%
echo Python base:    %PYBASE%
echo Python library: %PYLIB%   (%PYBITS%-bit)
echo Output file:    _quisk%SUFFIX%
if not "%PYBITS%"=="64" (echo ERROR: 64-bit Python is required & exit /b 1)

set SRCS=quisk.c sound.c is_key_down.c microphone.c utility.c sound_alsa.c sound_pulseaudio.c ^
 sound_portaudio.c sound_directx.c sound_wasapi.c filter.c extdemod.c freedv.c quisk_wdsp.c ^
 ac2yd\remote.c tci.c base64.c handshake.c sha1.c utf8.c ws.c

set DEFS=-DMS_WIN64 -DQUISK_HAVE_WASAPI -DQUISK_HAVE_DIRECTX
set LIBS=-L. -lfftw3-3 -lws2_32 -lwinmm -lole32 -loleaut32 -ldsound -ldxguid -lavrt -liphlpapi -luuid -lksuser

echo Compiling...
gcc -O2 -shared -o _quisk%SUFFIX% -I. -I"%FFTWINC%" -I"%PYINC%" %DEFS% %SRCS% ^
 -L"%PYBASE%" -L"%PYBASE%\libs" -l%PYLIB% %LIBS% ^
 -static-libgcc -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic
if errorlevel 1 (
  echo.
  echo BUILD FAILED - copy the messages above and send them to Claude.
  exit /b 1
)
echo.
echo BUILD OK: _quisk%SUFFIX%
echo Now copy it over the one in your installed Quisk folder (back up the original first).
endlocal
