# Supplemental local files

These archives contain the previously excluded generated dependencies, Python caches, and oversized inspection logs. Archive entries retain the four project folder paths.

Run `python supplemental-backup/restore.py` from the repository root to restore the files. The helper reassembles split archives, verifies their SHA-256 hashes, and extracts into the repository root. Existing project files may be overwritten by their archived versions. Allow enough free disk space for several GB of dependencies.

Authentication state (.sf and .sfdx) and old .git directories remain local. Reauthenticate on the destination computer; use this repository's Git history. Any additional omitted credential candidates are listed in UPLOAD-EXCLUSIONS.json.
