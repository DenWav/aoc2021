#!/usr/bin/php
<?php

$file_contents = file_get_contents("input.txt");
$parts = explode(",", $file_contents);
$nums = array_map('intval', $parts);

function step(int $days, int $val, array &$computed): int {
    if ($days === 0) {
        return 1;
    }

    if (array_key_exists($days, $computed)) {
        $computed_day = &$computed[$days];
        if (array_key_exists($val, $computed_day)) {
            return $computed_day[$val];
        }
    } else {
        $computed_day = [];
        $computed[$days] = &$computed_day;
    }

    $next_val = $val == 0 ? 6 : $val - 1;
    $own_count = step($days - 1, $next_val, $computed);
    if ($val === 0) {
        $own_count += step($days - 1, 8, $computed);
    }

    $computed_day[$val] = $own_count;
    return $own_count;
}

$days = 256;

$computed = [];
$count = 0;
foreach ($nums as $num) {
    $count += step($days, $num, $computed);
}

print $count;
