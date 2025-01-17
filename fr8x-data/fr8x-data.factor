! Copyright (C) 2014 Mark Green and contributors.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs bitstreams byte-arrays
fr8x-data-format-syntax fry io io.directories
io.encodings.binary io.files kernel math math.parser sequences
sequences.deep strings xml xml.traversal locals ;
FROM: io => read ;
FROM: assocs => change-at ;
RENAME: read bitstreams => bsread

IN: fr8x-data

TUPLE: chunkinfo
    { name string }
    { size integer }
    { count integer }
    { offset integer } ;

ERROR: loading-error desc ;

! Reads preamble part of a set file
: read-header ( -- bin )
    "\x8d" read-until
    [ "Missing end of preamble marker" loading-error ] unless ;

! Skips over bytes at the start of a setfile
! Note: although this seems to be "junk", the FR8X will reject files if it is changed
: chop-junk ( bin -- slice )
    CHAR: < over index [
        tail-slice
    ] [
        "Missing XML document in preamble" loading-error
    ] if* ;

: get-chunk-tags ( head -- vector )
    children>> second children-tags ;

: get-int-attr ( attrs name -- int )
    swap at*
    [ "Missing expected attribute in XML preamble" loading-error ] unless
    string>number ;

: parse-chunk-tag ( tag -- chunkspec )
    [ name>> main>> ] [ attrs>> ] bi
    "size" "number" "offset" [ get-int-attr ] tri-curry@ tri
    chunkinfo boa ;

: parse-chunk-tags ( vector -- chunks )
    [ parse-chunk-tag ] map ;

: parse-header ( -- chunks )
    read-header chop-junk bytes>xml get-chunk-tags parse-chunk-tags ;

: load-chunk ( chunkinfo offset -- chunkdata )
    swap
    [ offset>> + seek-absolute seek-input ] keep
    [ name>> ] [ count>> ] [ size>> ] tri '[ _ read ] replicate
    2array ;

: load-chunks ( chunkinfos -- chunkdatas )
    tell-input 1 - [ load-chunk ] curry map ;

! File format specs - these are based on the FR7X specs 
! Defines scData, pack-scData, unpack-scData

ROLAND-CHUNK-FORMAT: scData
    creator ascii 4 7
    type ascii 4 7
    ver ascii 4 7
    num ascii 4 7
    name ascii 8 7
    reverb-character integer 7
    reverb-prelpf integer 7
    reverb-time integer 7
    reverb-delay integer 7
    reverb-predelay integer 7
    reverb-level integer 7
    reverb-selected integer 7
    chorus-prelpf integer 7
    chorus-feedback integer 7
    chorus-delay integer 7
    chorus-rate integer 7
    chorus-depth integer 7
    chorus-sendrev integer 7
    chorus-senddelay integer 7
    chorus-level integer 7
    chorus-selected integer 7
    delay-prelpf integer 7
    delay-time-center integer 7
    delay-time-ratio-left integer 7
    delay-time-ratio-right integer 7
    delay-level-center integer 7
    delay-level-left integer 7
    delay-level-right integer 7
    delay-feedback integer 7
    delay-send-reverb integer 7
    delay-level integer 7
    delay-selected integer 7
    master-bar-recall integer 7
    index-icon integer 7
    bassoon integer 7
    edited integer 7
    dummy integer 15
    unknown intlist 89 7 ;

! Defines: trData, pack-trData, unpack-trData

ROLAND-CHUNK-FORMAT: trData
    register-name ascii 8 7 
    voice-timbre-cc00 intlist 10 7
    voice-timbre-cc32 intlist 10 7
    voice-timbre-pc intlist 10 7
    voice-on-off intlist 10 7
    voice-cassotto intlist 10 7
    voice-volume intlist 10 7
    orchestral-mode integer 7
    orchestral-tone-num integer 7
    musette-detune integer 7
    reverb-send integer 7
    chorus-send integer 7
    delay-send integer 7
    bellow-pitch-detune integer 7
    octave integer 7
    valve-noise-on-off integer 7
    valve-noise-volume integer 7
    valve-noise-cc00 integer 7
    valve-noise-cc32 integer 7
    valve-noise-pc integer 7
    link-bass integer 7
    link-orch-bass integer 7
    link-orch-chord-freebass integer 7
    aftertouch-pitch-down integer 7
    note-tx-filter integer 7
    note-on-velocity integer 7
    midi-octave integer 7
    midi-cc0 integer 12
    midi-cc32 integer 12
    midi-pc integer 12
    midi-aftertouch integer 12
    midi-volume integer 12
    midi-panpot integer 12
    midi-reverb integer 12
    midi-chorus integer 12
    edited integer 7
    unknown intlist 244 7 ;

! Defines orData, pack-orData, unpack-orData

ROLAND-CHUNK-FORMAT: orData
   custom-name ascii 12 7
   patch-cc00 integer 7
   patch-cc32 integer 7
   patch-pc integer 7
   patch-1-cc00 integer 7
   patch-1-cc32 integer 7
   patch-1-pc integer 7
   patch-1-volume integer 7
   patch-1-octave integer 7
   dynamic-mode integer 7
   reg-edited integer 7
   vtw-preset-ref integer 7
   vtw-preset-edited integer 7
   unknown intlist 74 7 
   overhang integer 2 ;

! Defines obrData, pack-obrData, unpack-obrData

ROLAND-CHUNK-FORMAT: obrData
    custom-name ascii 12 7
    patch-cc00 integer 7
    patch-cc32 integer 7
    patch-pc integer 7
    dynamic-mode integer 7
    reg-edited integer 7
    vtw-preset-ref integer 7
    vtw-preset-edited integer 7
    unknown intlist 56 7 
    overhang integer 3 ;

! Defines obcrfData, pack-obcrfData, unpack-obcrfData
! These seem to work for OBC_R and OBF_R although unknowns may be different
ROLAND-CHUNK-FORMAT: obcrfData
    custom-name ascii 12 7
    patch-cc00 integer 7
    patch-cc32 integer 7
    patch-pc integer 7
    dynamic-mode integer 7
    reg-edited integer 7
    vtw-preset-ref integer 7
    vtw-preset-edited integer 7
    unknown intlist 63 7 
    overhang integer 2 ;

! Defines brData, pack-brData, unpack-brData
ROLAND-CHUNK-FORMAT: brData
    register-name ascii 13 7
    voice-timbre-cc00 intlist 10 7
    voice-timbre-cc32 intlist 10 7
    voice-timbre-pc intlist 10 7
    voice-on-off intlist 10 7
    voice-volume intlist 10 7
    keyrange-16 integer 7
    keyrange-8 integer 7
    active-bass-state integer 7
    note-tx-filter integer 7
    note-on-velocity integer 7
    midi-octave integer 7
    drumkit-note-number intlist 3 12
    drumkit-note-volume intlist 3 12
    midi-cc00 integer 12
    midi-cc32 integer 12
    midi-pc integer 12
    midi-volume integer 12
    midi-panpot integer 12
    midi-reverb integer 12
    midi-chorus integer 12
    midi-bellow integer 7
    edited integer 1
    unknown intlist 3 7
    overhang integer 4 ;

! Defines bcrData, pack-bcrData, unpack-bcrData
ROLAND-CHUNK-FORMAT: bcrData
    register-name ascii 13 7
    voice-timbre-cc00 intlist 10 7
    voice-timbre-cc32 intlist 10 7
    voice-timbre-pc intlist 10 7
    voice-on-off intlist 10 7
    voice-volume intlist 10 7
    drumkit-note-number intlist 3 12
    drumkit-note-volume intlist 3 12
    reverb-send integer 7
    chorus-send integer 7
    delay-send integer 7
    bellow-pitch-detune integer 7
    growl-on-off integer 7
    growl-volume integer 7
    growl-16-cc00 integer 7
    growl-16-cc32 integer 7
    growl-16-pc integer 7
    growl-84-cc00 integer 7
    growl-84-cc32 integer 7
    growl-84-pc integer 7
    bnoise-on-off integer 7
    bnoise-volume integer 7
    bnoise-cc00 integer 7
    bnoise-cc32 integer 7
    bnoise-pc integer 7
    note-tx-filter integer 7
    note-on-velocity integer 7
    midi-octave integer 7
    midi-cc00 integer 12
    midi-cc32 integer 12
    midi-pc integer 12
    midi-volume integer 12
    midi-panpot integer 12
    midi-reverb integer 12
    midi-chorus integer 12
    midi-bellow integer 7
    edited integer 7
    midi-drum-tx integer 1
    dummy-edited integer 5
    dummy integer 7 
    overhang integer 4 ;



! Encode or decode all known chunks and replace content of setfile dictionary with decoded version
! DO NOT PUT ANY PACKS/UNPACKERS IN HERE IF THEY DO NOT PAST CHUNK-SYMMETRY-TEST 
! AND CHECK FILE-SYMMETRY-TEST IS PASSED BEFORE COMMIT !!

       

: decode-known-chunks ( chunks -- chunks )
    "TR" over [ [ <msb0-bit-reader> unpack-trData ] map ] change-at 
    "SC" over [ first <msb0-bit-reader> unpack-scData ] change-at 
    "O_R" over [ [ <msb0-bit-reader> unpack-orData ] map ] change-at 
    "OB_R" over [ [ <msb0-bit-reader> unpack-obrData ] map ] change-at 
    "OBC_R" over [ [ <msb0-bit-reader> unpack-obcrfData ] map ] change-at 
    "OFB_R" over [ [ <msb0-bit-reader> unpack-obcrfData ] map ] change-at 
    "BR" over [ [ <msb0-bit-reader> unpack-brData ] map ] change-at 
    "BCR" over [ [ <msb0-bit-reader> unpack-bcrData ] map ] change-at ;
     

: encode-known-chunks ( chunks -- chunks )
    "TR" over [ [ pack-trData ] map ] change-at 
    "SC" over [ pack-scData { } swap suffix ] change-at 
    "O_R" over [ [ pack-orData ] map ] change-at 
    "OB_R" over [ [ pack-obrData ] map ] change-at 
    "OBC_R" over [ [ pack-obcrfData ] map ] change-at 
    "OFB_R" over [ [ pack-obcrfData ] map ] change-at 
    "BR" over [ [ pack-brData ] map ] change-at 
    "BCR" over [ [ pack-bcrData ] map ] change-at ;


: parse-set-file ( -- data )
    parse-header load-chunks decode-known-chunks ;

: load-set-file ( fn -- data )
    binary [ parse-set-file ] with-file-reader ;


: get-chunk ( alist id -- chunk )
    swap at* [ "Missing chunk type" loading-error ] unless ;

: write-chunks ( chunks -- )
    encode-known-chunks values flatten >byte-array write flush ;

: save-set-file ( data fn -- )
    "vocab:fr8x-data/standard.preamble" over copy-file
    binary [ write-chunks ] with-file-appender ;


! Name of any set file to use for testing purposes
! Recommended to use one of the exported FR8X system files -
! these are not included due to potential Roland copyright
! If you can't get one, try the Dallape sets from the Yahoo group
CONSTANT: test-file-name "FR-8X_SET_012.ST8"

! For quickly loading the test file for testing at the console
: load-test-file ( -- head ) test-file-name load-set-file ;

