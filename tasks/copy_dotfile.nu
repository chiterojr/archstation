use ../lib/types.nu [mk-task, mk-result]

export def generate [config: record] {
  let source_root = $config.source_dir | path expand
  let dest_root = $config.dest_dir | path expand

  glob $"($source_root)/**/*"
  | sort
  | where { |p| ($p | path type) == "file" }
  | each { |src_path|
      let rel_path = $src_path | str replace $source_root ""
      let dest_path = $"($dest_root)($rel_path)"
      let label = $"dotfile: ($rel_path)"

      mk-task "copy_dotfile" $label {
        if ($dest_path | path exists) {
          let src_hash = open --raw $src_path | hash sha256
          let dst_hash = open --raw $dest_path | hash sha256

          if $src_hash == $dst_hash {
            mk-result "copy_dotfile" $label "skipped" "destination matches source"
          } else {
            mk-result "copy_dotfile" $label "failed" $"SAFETY: destination file differs: ($dest_path)"
          }
        } else {
          let dest_dir = $dest_path | path dirname
          mkdir $dest_dir
          cp $src_path $dest_path
          mk-result "copy_dotfile" $label "executed" $"copied to ($dest_path)"
        }
      }
  }
}

export def ingest [config: record] {
  let source_root = $config.source_dir | path expand
  let dest_root = $config.dest_dir | path expand

  # Only check files already managed by archstation (present in dotfiles/)
  let diverged = glob $"($source_root)/**/*"
    | sort
    | where { |p| ($p | path type) == "file" }
    | each { |src_path|
        let rel_path = $src_path | str replace $source_root ""
        let dest_path = $"($dest_root)($rel_path)"

        if ($dest_path | path exists) {
          let src_hash = open --raw $src_path | hash sha256
          let dst_hash = open --raw $dest_path | hash sha256

          if $src_hash != $dst_hash {
            { rel_path: $rel_path, src_path: $src_path, dest_path: $dest_path }
          }
        }
    }
    | compact

  if ($diverged | is-empty) {
    print $"(ansi green)All managed dotfiles match. Nothing to ingest.(ansi reset)"
    return
  }

  print $"(ansi cyan_bold)Found ($diverged | length) dotfiles where system differs from repo:(ansi reset)"
  print ""

  mut ingested_count = 0

  for entry in $diverged {
    print $"(ansi cyan_bold)dotfile: ($entry.rel_path)(ansi reset)"
    print ""

    # Show a short diff (repo vs system)
    let diff_result = ^diff --unified=3 --color=always $entry.src_path $entry.dest_path | complete
    print $diff_result.stdout
    print ""

    let choice = ["update repo" "skip" "diff full"] | input list $"Action for ($entry.rel_path): "

    match $choice {
      "update repo" => {
        cp $entry.dest_path $entry.src_path
        print $"(ansi green)  Updated repo: ($entry.rel_path)(ansi reset)"
        $ingested_count = $ingested_count + 1
      },
      "diff full" => {
        let full_diff = ^diff --color=always $entry.src_path $entry.dest_path | complete
        print $full_diff.stdout

        let confirm = ["update repo" "skip"] | input list $"Action for ($entry.rel_path): "
        if $confirm == "update repo" {
          cp $entry.dest_path $entry.src_path
          print $"(ansi green)  Updated repo: ($entry.rel_path)(ansi reset)"
          $ingested_count = $ingested_count + 1
        } else {
          print $"(ansi yellow)  Skipped(ansi reset)"
        }
      },
      _ => {
        print $"(ansi yellow)  Skipped(ansi reset)"
      }
    }
    print ""
  }

  print $"(ansi cyan_bold)--- ingest summary ---(ansi reset)"
  print $"(ansi green)($ingested_count)(ansi reset) dotfiles updated in repo, (ansi yellow)($diverged | length | $in - $ingested_count)(ansi reset) skipped"
}

export def check [config: record] {
  let source_root = $config.source_dir | path expand
  let dest_root = $config.dest_dir | path expand

  glob $"($source_root)/**/*"
  | sort
  | where { |p| ($p | path type) == "file" }
  | each { |src_path|
      let rel_path = $src_path | str replace $source_root ""
      let dest_path = $"($dest_root)($rel_path)"
      let label = $"dotfile: ($rel_path)"

      if ($dest_path | path exists) {
        let is_symlink = ($dest_path | path type) == "symlink"
        let src_hash = open --raw $src_path | hash sha256
        let dst_hash = open --raw $dest_path | hash sha256

        if $src_hash == $dst_hash {
          { task_type: "copy_dotfile", label: $label, status: "ok", detail: (if $is_symlink { "symlink, matches" } else { "matches" }) }
        } else {
          { task_type: "copy_dotfile", label: $label, status: "differs", detail: $dest_path }
        }
      } else {
        { task_type: "copy_dotfile", label: $label, status: "missing", detail: $dest_path }
      }
  }
}
