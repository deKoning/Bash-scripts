#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

# Timestamp for the log file
TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
LOGFILE="movie_organizer_${TIMESTAMP}.log"

# Function to log messages with timestamp + icons
log() {
    local level="$1"
    local message="$2"
    local now
    now="$(date +"%Y-%m-%d %H:%M:%S")"

    case "$level" in
        SUCCESS) icon="✅";;
        ERROR) icon="❌";;
        WARN) icon="⚠️ ";;
        INFO) icon="ℹ️ ";;
        *) icon="";;
    esac

    echo "[$now] [$level] $icon $message" | tee -a "$LOGFILE"
}

# Junk patterns to remove from movie titles
JUNK="2160p|1080p|720p|480p|UHD|HDR|DV|Dolby|Vision|WEB[- ]?DL|WEB[- ]?Rip|Blu[- ]?ray|Bluray|BRRip|BDRip|HDRip|CAM|TS|TC|SCR|x264|h\.?264|x265|HEVC|AV1|10bit|8bit|AAC|AC-?3|E?AC-?3|DDP|EAC3|DTS(-?HD)?|Atmos|TrueHD|xvid|divx|mpeg|h\.?265|REMUX|REPACK|PROPER|EXTENDED|CUT|IMAX|Dual(-?Audio)?|Multi|Subs?|Hardsub|Softsub|NF|AMZN|iTA|ITA|ENG|EN|NL|SPA|GER|FRENCH|PL|RU|KO|JP|HC|HCsub|VOSTFR|LAT|ES|PT|TR|AR|CZ|SK|mkv|mp4|avi"

normalize() {
    echo "$1" \
    | sed -E 's/[][(){}]/ /g' \
    | tr '._-' ' ' \
    | sed -E 's/ +/ /g; s/^ //; s/ $//'
}

log "INFO" "Movie Organizer started."
log "INFO" "Processing directory: $ROOT"
log "INFO" "Log file: $LOGFILE"

# Collect all mkv and mp4 files first to avoid loops
mapfile -t files < <(find "$ROOT" -type f \( -iname "*.mkv" -o -iname "*.mp4" \))

for filepath in "${files[@]}"; do
    filename="$(basename "$filepath")"
    dirpath="$(dirname "$filepath")"
    ext="${filename##*.}"

    log "INFO" "Processing: $filename"

    # Calculate checksum before moving
    checksum_before=$(sha1sum "$filepath" | awk '{print $1}')

    name_noext="${filename%.*}"
    clean="$(normalize "$name_noext")"

    # Extract year
    year="$(echo "$clean" | grep -oE '\b(19[0-9]{2}|20[0-9]{2})\b' | head -n 1 || true)"

    title_part="$clean"
    if [ -n "$year" ]; then
        title_part="$(echo "$clean" | sed -E "s/\b$year\b.*//")"
    fi

    # Strip junk tokens
    if [ -n "$title_part" ]; then
        title_part="$(echo "$title_part" \
        | sed -E "s/\b($JUNK)\b//Ig" \
        | sed -E 's/ +/ /g; s/^ //; s/ $//')"
    fi

    # Fallback title from parent folder if needed
    if [ -z "$title_part" ]; then
        parent="$(basename "$dirpath")"
        title_part="$(normalize "$parent")"
        title_part="$(echo "$title_part" \
        | sed -E "s/\b($JUNK)\b//Ig" \
        | sed -E 's/ +/ /g; s/^ //; s/ $//')"
        [ -z "$title_part" ] && title_part="Unknown Title"
    fi

    # Fallback year from parent folder
    if [ -z "$year" ]; then
        year="$(echo "$(basename "$dirpath")" | grep -oE '(19[0-9]{2}|20[0-9]{2})' | head -n 1 || true)"
    fi

    # Build folder and file names
    if [ -n "$year" ]; then
        folder="$ROOT/$title_part ($year)"
        newname="$title_part ($year).$ext"
    else
        folder="$ROOT/$title_part"
        newname="$title_part.$ext"
    fi

    mkdir -p "$folder"

    # Prevent overwrites by adding suffix
    target="$folder/$newname"
    if [ -e "$target" ]; then
        i=1
        base="${newname%.*}"
        while [ -e "$folder/$base - copy$i.$ext" ]; do i=$((i+1)); done
        target="$folder/$base - copy$i.$ext"
        log "WARN" "Duplicate detected. Renaming target to: $(basename "$target")"
    fi

    # Move video
    mv "$filepath" "$target"

    # Verify checksum after moving
    checksum_after=$(sha1sum "$target" | awk '{print $1}')
    if [ "$checksum_before" != "$checksum_after" ]; then
        log "ERROR" "Checksum mismatch for '$filename' — Move aborted."
        exit 1
    else
        log "SUCCESS" "Verified: $filename moved successfully."
    fi

    # Handle subtitles in the same source folder
    basename_noext="${filename%.*}"
    while IFS= read -r -d '' subfile; do
        subname="$(basename "$subfile")"
        subext="${subname##*.}"

        lang_tag="$(echo "$subname" \
        | sed -E "s/^$(printf '%s' "$basename_noext" | sed -E 's/([][(){}.^$+*?|\\/])/\\\1/g')//" \
        | sed -E "s/\.$subext$//; s/^\.//")"

        if [ -n "$year" ]; then
            subbase="$title_part ($year)"
        else
            subbase="$title_part"
        fi
        [ -n "$lang_tag" ] && subbase="$subbase.$lang_tag"

        subtarget="$folder/$subbase.$subext"

        if [ -e "$subtarget" ]; then
            i=1
            while [ -e "${subtarget%.$subext} - copy$i.$subext" ]; do i=$((i+1)); done
            subtarget="${subtarget%.$subext} - copy$i.$subext"
            log "WARN" "Subtitle duplicate detected. Renaming target to: $(basename "$subtarget")"
        fi

        # Checksum verify subtitles
        sub_checksum_before=$(sha1sum "$subfile" | awk '{print $1}')
        mv "$subfile" "$subtarget"
        sub_checksum_after=$(sha1sum "$subtarget" | awk '{print $1}')

        if [ "$sub_checksum_before" != "$sub_checksum_after" ]; then
            log "ERROR" "Checksum mismatch for subtitle '$subname'."
            exit 1
        else
            log "SUCCESS" "Verified subtitle: $subname moved."
        fi
    done < <(find "$dirpath" -maxdepth 1 -type f -iname "${basename_noext}*.srt" -print0)
done

log "INFO" "Movie Organizer completed successfully."

