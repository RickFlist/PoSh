@echo OFF
SET input_folder=Input
SET output_folder=Output
SET ffmpeg_path=ffmpeg.exe
if not exist "%output_folder%" mkdir "%output_folder%"

REM Settings

SET ext=mkv
SET format=matroska

REM SET videofilter=-pix_fmt yuv444p
REM SET resolution=-sws_flags lanczos -s 1280x720
SET encoder=h264_nvenc
REM SET encoder=hevc_nvenc
SET preset=hq
SET cq=20
SET sample=-sample_fmt s16
SET khz=-ar 48000
REM SET audiofilter=-af aresample=resampler=soxr:precision=28:dither_method=shibata %sample% %khz%
SET videoencoder=-c:v %encoder% -rc constqp -global_quality %cq% -preset %preset% -rc-lookahead 32 -g 600
SET audioencoder=-c:a flac -compression_level 12

REM Settings end

SET params=-i "%%~f" -map_metadata -1 %resolution% %videofilter% %audiofilter% %audioencoder% %videoencoder% -f %format% "%output_folder%\%%~nf.%ext%"



FOR %%f IN (%input_folder%\*.*) DO (

IF EXIST "%output_folder%\%%~nf.%ext%" (
echo.
echo *************************************
echo Deleting: %output_folder%\%%~nf.%ext%
echo *************************************
echo.
del /F "%output_folder%\%%~nf.%ext%"
)

"%ffmpeg_path%" %params%

)

echo.
echo *************************************
echo Done!
echo *************************************
echo.

pause