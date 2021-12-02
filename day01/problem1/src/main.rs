/*
 * Copyright (c) 2021 Kyle Wood (DenWav)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, version 3 only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

use std::io::stdin;
use std::process::exit;

fn main() {
    match run() {
        Ok(v) => println!("{}", v),
        Err(e) => {
            eprintln!("{}", e);
            exit(1);
        }
    }
}

fn run() -> Result<i32, String> {
    let mut counter = 0;
    let mut prev_value: Option<i32> = None;

    let mut line = String::new();
    loop {
        match stdin().read_line(&mut line) {
            Ok(0) => break, // EOF
            Ok(_) => {}
            Err(e) => return Err(format!("Failed to read from stdin: {}", e))
        }

        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue
        }

        let value = match trimmed.parse::<i32>() {
            Ok(v) => v,
            Err(e) => return Err(format!("Failed to parse '{}' as an integer: {}", line, e))
        };

        if let Some(prev) = prev_value {
            if prev < value {
                counter += 1;
            }
        }
        prev_value = Some(value);

        line.clear();
    }

    return Ok(counter);
}
