Arjinius Client music
=====================

These 15 original Duris tracks (about 72 minutes) appear in the music player
at the top right of the interface. Shuffle is on by default; with it off they
play in number order. The player shows each title without its number.
Tracks marked "II" are a second take of the same piece.

Your own music goes in the arjui_music folder of your Mudlet profile instead
(type "ui music folder" to open it), so a package update never replaces it.
Type "ui music rescan" after adding files. MP3 plays in every supported
Mudlet; Mudlet 5 also plays Ogg, Opus, FLAC, AAC and WAV.

Encoding (for maintainers adding or replacing a bundled track)
--------------------------------------------------------------
Each track is gain-matched to -17 LUFS with a plain volume change (no
compression or limiting), then encoded as MP3 VBR -V7, 44.1 kHz stereo, with
cover art and tags removed except title:

  ffmpeg -i SOURCE -map 0:a -map_metadata -1 -af volume=<-17 minus source LUFS>dB \
    -ar 44100 -ac 2 -c:a libmp3lame -q:a 7 -compression_level 0 \
    -metadata title="TITLE" -metadata album=Duris "NN - TITLE.mp3"

Measure the source loudness with:
  ffmpeg -i SOURCE -map 0:a -af ebur128=peak=true -f null -

The numbers were assigned in random order, with no song's two takes adjacent.
