[ a b c d e f ]
| do { |list|
  $list
  | reduce --fold [] {
    |it, acc| if ($acc | length) mod 3 == 0 {
      $acc | append $it
    } else {
      $acc
    }
  }
} $in
