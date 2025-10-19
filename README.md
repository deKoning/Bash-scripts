# 🎬 Movie Organizer Script

This script automatically **restructures and cleans your movie library** by:

- 🧹 Renaming video files to `Movie Title (YEAR).ext`
- 📂 Moving them into matching folders: `Movie Title (YEAR)/`
- 📝 Moving and renaming matching subtitles
- 🧠 Stripping out scene junk tags (`1080p`, `x264`, `Bluray`, etc.)
- 🔐 Verifying **file integrity** using SHA1 checksums before and after moving
- 📜 Logging everything to a timestamped log file
- ✅ Displaying clear feedback in the terminal

---

## 📦 Requirements

- A Unix-like environment (Linux, macOS, WSL)
- `bash`
- `sed`, `grep`, `find`, `sha1sum`, and `tee` (standard on most distros)

---

## 🚀 Installation

1. Download the script and place it somewhere in your `$PATH` or in your movie folder.
   ```bash
   curl -O https://example.com/restructure_movies.sh
````

2. Make the script executable:

   ```bash
   chmod +x restructure_movies.sh
   ```

---

## 🧪 Usage

To run the script on your movie library:

```bash
./restructure_movies.sh /path/to/movies
```

If no path is given, it defaults to the **current directory**:

```bash
./restructure_movies.sh
```

### Example

**Before**:

```
/movies
├── Mission.Impossible.The.Final.Reckoning.2025.1080p.x264-CYBER.mkv
└── Mission.Impossible.The.Final.Reckoning.2025.ENG.srt
```

**After**:

```
/movies
└── Mission Impossible The Final Reckoning (2025)
    ├── Mission Impossible The Final Reckoning (2025).mkv
    └── Mission Impossible The Final Reckoning (2025).ENG.srt
```

---

## 🧾 Log Files

Every run generates a log file named:

```
movie_organizer_YYYY-MM-DD_HH-MM-SS.log
```

The log includes:

* Date and time of each action
* Files moved and their new names
* Duplicate handling
* Checksum verification
* Any warnings or errors

Example log entry:

```
[2025-10-19 14:37:12] [SUCCESS] ✅ Verified: Takeout.2025.mkv moved successfully.
```

---

## 🛡️ Safety Features

* **Checksum Verification:**
  Every file is hashed before and after moving to guarantee data integrity.

* **No Overwrites:**
  If a file with the same name already exists, the script renames the new one with a `- copy1` suffix.

* **No Mixing of Different Movies:**
  Folder names are determined solely from the filename of each video file, not from loose year matches.

* **Logging:**
  All actions are written to a timestamped log file for easy review.

---

## 🧰 Tips

* For a **test run**, copy a few movies to a separate folder and run the script there first.
* To see every command as it executes, you can add `set -x` to the top of the script temporarily.
* If your library lives on a NAS or external drive, it’s recommended to run it locally for speed.

---

## 🧭 Roadmap (Optional Ideas)

* [ ] Dry run mode (`--simulate`)
* [ ] Support for more subtitle formats (`.ass`, `.sub`)
* [ ] Automatic handling of `.nfo`, `.jpg`, and other sidecar files
* [ ] Hash-based duplicate detection

---

## 🧑‍💻 Author

Crafted with care and nerdy joy by **Vincent de Koning** 🧠✨

---

