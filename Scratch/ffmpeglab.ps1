<#

     --enable-cuda --enable-nvenc
#>

$glbTimer = ( New-Object -TypeName System.Diagnostics.Stopwatch )
$opTimer = ( New-Object -TypeName System.Diagnostics.Stopwatch )

$glbTimer.Restart()
$opTimer.Restart()

$cmdName = ( 'ffmpeg')
$cmdPath = ( Get-Command -Name $cmdName -ErrorAction SilentlyContinue )

if ( -not $cmdPath )
{
     throw ( New-Object -TypeName System.IO.FileNotFoundException -ArgumentList ( 'Cannot find {0}. Check your path and try again' -f $cmdName) )
}

$ext = ( 'mp4' )
$format = ( 'h264' )

$videofilter = ( '-pix_fmt yuv444p' )
$resolution = ( '-sws_flags lanczos -s 1280x720' )
$encoder = ( 'h264_nvenc' )
# $encoder = ( 'hevc_nvenc' )
$preset = ( 'hq' )
$cq = ( '20' )
$sample = ( '-sample_fmt s16' )
$khz = ( '-ar 48000' )
$audiofilter = ( '-af aresample=resampler=soxr:precision=28:dither_method=shibata {0} {1}' -f $sample,$khz )
$videoencoder = ( '-c:v {0} -rc constqp -global_quality {1} -preset {2} -rc-lookahead 32 -g 300' -f $encoder,$cq,$preset )
$audioencoder = ( '-c:a flac -compression_level 12' )

$inputFile = "D:\Mature\1.0-Formatted\[Brazzers]-[01]-[01]-[Aaliyah Hadid; Anya Ivy]-[BGB]-[2017-04-23]-[Daughter]-[BGG; Teen; Denim Shorts].mp4"
$outputFile = "D:\Mature\1.0-Formatted\[Brazzers]-[01]-[01]-[Aaliyah Hadid; Anya Ivy]-[BGB]-[2017-04-23]-[Daughter]-[BGG; Teen; Denim Shorts]-ffmpg.mp4"

$cmdParams = ( '-i "{0}" -map_metadata -1 {1} {2} {3} {4} {5} -f {6} "{7}"' -f `
     $inputFile,`        # 0
     $resolution,`       # 1
     $videofilter,`      # 2
     $audiofilter,`      # 3
     $audioencoder,`     # 4
     $videoencoder,`     # 5
     $format,`           # 6
     $outputFile         # 7
)

Write-Host ( "[{0} | Ttl {1} | Op {2}] : Starting encode for `r`n`r`n{3} `r`n`r`n`twith arguments`r`n`r`n{4}" -f `
     (Get-Date -Format 'MM/dd HH:mm:ss.ffff'),`        # 0
     $glbTimer.Elapsed.ToString(),`                    # 1
     $opTimer.Elapsed.ToString(),`                     # 2
     $inputFile,`                                      # 3
     $cmdParams                                        # 4
)

Start-Process -FilePath $cmdPath -ArgumentList $cmdParams -Wait -NoNewWindow