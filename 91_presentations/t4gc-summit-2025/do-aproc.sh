# extract audio from video
ffmpeg -i 00026.MTS -vn -acodec pcm_s16le vfile-audio-ref.wav
# align audio uses hardcoded filename
python3 align-audio.py # 11.516375 offset
# audio recoding on the Zoom H1 is started first. Use the offset
# to trim the beginning. This will start at the beginning of the
# video
ffmpeg -i ZOOM0006.WAV -ss 11.516375 atrim.wav
# Normalize volume
sh avol-normalize.sh atrim.wav
