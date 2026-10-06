#!/usr/bin/env nu

def main [] {
    let remote = $"r2:($env.BACKUP_BUCKET)"
    let now = date now
    let stamp = $now | format date "%Y%m%d-%H%M%S"
    let month_start = $now | format date "%Y%m01"
    let week_start = $now - ((($now | format date "%u" | into int) - 1) * 1day) | format date "%Y%m%d"

    let existing = ^rclone lsf --recursive --dirs-only --max-depth 2 $remote
        | lines
        | parse "{tier}/{stamp}/"

    let tier = if ($existing | where tier == "monthly" and stamp >= $month_start | is-empty) {
        "monthly"
    } else if ($existing | where tier in ["monthly" "weekly"] and stamp >= $week_start | is-empty) {
        "weekly"
    } else {
        "daily"
    }

    let local = $env.FILE_PWD | path join template backups $stamp
    let dest = $"($remote)/($tier)/($stamp)"

    ^bash ($env.FILE_PWD | path join template scripts backup.sh) $local

    print $"Uploading to ($dest)"

    # SHA256SUMS goes last, so a folder in R2 without it is an incomplete upload.
    ^rclone copy $local $dest --exclude SHA256SUMS
    ^rclone copy $local $dest --include SHA256SUMS
    ^rclone check $local $dest --one-way

    rm --recursive $local

    print $"Uploaded ($stamp) as a ($tier) backup"
}
