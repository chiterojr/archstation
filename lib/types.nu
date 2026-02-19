export def mk-task [task_type: string, label: string, executor: closure] {
  { task_type: $task_type, label: $label, execute: $executor }
}

export def mk-result [task_type: string, label: string, status: string, detail: string] {
  { task_type: $task_type, label: $label, status: $status, detail: $detail }
}
