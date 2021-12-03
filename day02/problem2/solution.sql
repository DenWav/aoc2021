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

DROP TABLE IF EXISTS input;
DROP TYPE IF EXISTS DIRECTION;

CREATE TYPE DIRECTION AS ENUM ('forward', 'down', 'up');
CREATE TABLE input (
    id        SERIAL,
    direction DIRECTION,
    value     INT
);

COPY input (direction, value)
FROM '/Users/kyle/input.txt'
DELIMITER ' ';


SELECT (
    SELECT sum(i.value)
    FROM input i
    WHERE i.direction = 'forward'
) * (
    SELECT sum(i2.value * i2.aim)
    FROM (
        SELECT
            i.direction,
            i.value,
            sum(
                CASE
                    WHEN i.direction = 'down' THEN i.value
                    WHEN i.direction = 'up' THEN -i.value
                END
            ) OVER (ORDER BY i.id) aim
        FROM input i
    ) i2
    WHERE i2.direction = 'forward'
) result;
