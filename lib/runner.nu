def colorize-status [status: string] {
  match $status {
    "executed" => $"(ansi green)executed(ansi reset)",
    "skipped" => $"(ansi yellow)skipped(ansi reset)",
    "failed" => $"(ansi red)failed(ansi reset)",
    _ => $status
  }
}

export def run-tasks [tasks: list] {
  mut results = []

  for task in $tasks {
    let result = do $task.execute
    let colored = colorize-status $result.status
    print $"  ($colored)  ($result.label)"

    $results = ($results | append $result)

    if $result.status == "failed" {
      print ""
      print $"(ansi red)FATAL: ($result.detail)(ansi reset)"
      break
    }
  }

  print ""
  print $"(ansi cyan_bold)--- summary ---(ansi reset)"
  let summary = $results | group-by status | items { |status, rows|
    { status: (colorize-status $status), count: ($rows | length) }
  }
  print ($summary | table)

  $results
}
