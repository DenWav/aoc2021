#!/usr/bin/php
<?php

$file_contents = file_get_contents("input.txt");
$parts = explode(",", $file_contents);
$nums = array_map('intval', $parts);

function step(array $nums): array{
    $new_nums = [];
    foreach ($nums as $num) {
        if ($num === 0) {
            $new_nums[] = 8; // child
            $new_nums[] = 6; // parent
        } else {
            $new_nums[] = $num - 1;
        }
    }
    return $new_nums;
}

for ($i = 0; $i < 80; $i++) {
    $nums = step($nums);
}

print count($nums);
