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
