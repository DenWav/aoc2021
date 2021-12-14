#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct coordinate {
    uint32_t x;
    uint32_t y;
};

enum direction {
    X,
    Y
};

struct instruction {
    enum direction dir;
    uint32_t value;
};

#pragma clang diagnostic push
#pragma ide diagnostic ignored "bugprone-macro-parentheses"

#define append(type, name)                                                          \
    void append##name(type **data, uint32_t *count, uint32_t index, type *single) { \
        if (*count == index) {                                                      \
            if (*count == 0) {                                                      \
                *count = 10;                                                        \
            } else {                                                                \
                *count *= 2;                                                        \
            }                                                                       \
            const size_t size = *count * sizeof(type *);                            \
                                                                                    \
            if (*data == NULL) {                                                    \
                *data = (type *) malloc(size);                                      \
            } else {                                                                \
                *data = (type *) realloc(*data, size);                              \
            }                                                                       \
        }                                                                           \
                                                                                    \
        (*data)[index] = *single;                                                   \
    }

#define truncate(type, name)                                            \
    void truncate##name(type **data, uint32_t *count, uint32_t index) { \
        *data = (type *) realloc(*data, index * sizeof(type *));        \
        *count = index;                                                 \
    }

#pragma clang diagnostic pop

append(char *, String)
append(struct coordinate, Coordinate)
append(struct instruction, Instruction)

truncate(char *, String)
truncate(struct coordinate, Coordinate)
truncate(struct instruction, Instruction)

struct coordinate * parseCoord(char* line);
struct instruction * parseInstruction(char* line);
void readLines(FILE *file, char ***lines, uint32_t *lineCount);
void freeLines(char ***lines, uint32_t lineCount);

void doFold(struct instruction *instr, struct coordinate **coords, uint32_t *coordCount);
void mergeCoords(struct coordinate **coords, uint32_t *coordCount);
void printCoords(const struct coordinate *coords, uint32_t coordCount);

int main() {
    FILE *file = fopen("./input.txt", "r");

    char **lines = NULL;
    uint32_t lineCount = 0;
    readLines(file, &lines, &lineCount);
    fclose(file);

    struct coordinate *coords = NULL;
    uint32_t coordCount = 0, coordIndex = 0;

    struct instruction *instrs = NULL;
    uint32_t instrCount = 0, instrIndex = 0;

    uint32_t i;
    for (i = 0; i < lineCount; ++i) {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "DanglingPointer"
        struct coordinate *coord = parseCoord(lines[i]);
        if (coord != NULL) {
            appendCoordinate(&coords, &coordCount, coordIndex++, coord);
            free(coord);
        }

        struct instruction *instr = parseInstruction(lines[i]);
        if (instr != NULL) {
            appendInstruction(&instrs, &instrCount, instrIndex++, instr);
            free(instr);
        }
#pragma clang diagnostic pop
    }
    freeLines(&lines, lineCount);

    truncateCoordinate(&coords, &coordCount, coordIndex);
    truncateInstruction(&instrs, &instrCount, instrIndex);

    for (i = 0; i < instrCount; ++i) {
        doFold(instrs + i, &coords, &coordCount);
    }

    printCoords(coords, coordCount);

    free(coords);
    free(instrs);

    return 0;
}

void doFold(struct instruction *instr, struct coordinate **coords, uint32_t *coordCount) {
    uint32_t count = *coordCount;
    uint32_t i;
    for (i = 0; i < count; ++i) {
        struct coordinate *c = *coords + i;
        if (instr->dir == X && c->x > instr->value) {
            c->x = (instr->value << 1) - c->x;
        } else if (instr->dir == Y && c->y > instr->value) {
            c->y = (instr->value << 1) - c->y;
        }
    }

    mergeCoords(coords, coordCount);
}

void mergeCoords(struct coordinate **coords, uint32_t *coordCount) {
    // Don't bother being more memory or lookup efficient, not worth the effort here.
    struct coordinate *newCoords = NULL;
    uint32_t newCoordCount = 0, newCoordIndex = 0;

    uint32_t count = *coordCount;
    uint32_t i;
    for (i = 0; i < count; ++i) {

        uint32_t curX = (*coords)[i].x;
        uint32_t curY = (*coords)[i].y;

        if (newCoords != NULL) {
            uint32_t j;
            for (j = 0; j < newCoordIndex; ++j) {
                uint32_t newX = newCoords[j].x;
                uint32_t newY = newCoords[j].y;

                if (newX == curX && newY == curY) {
                    goto endOuterLoop;
                }
            }
        }

        appendCoordinate(&newCoords, &newCoordCount, newCoordIndex++, *coords + i);

        endOuterLoop:;
    }

    truncateCoordinate(&newCoords, &newCoordCount, newCoordIndex);
    *coords = newCoords;
    *coordCount = newCoordCount;
}

struct coordinate * parseCoord(char *line) {
    char *endptr;
    uint32_t x = strtol(line, &endptr, 10);
    if (endptr == line) {
        return NULL;
    }

    uint32_t y = strtol(endptr + 1, NULL, 10);
    if (endptr == line) {
        return NULL;
    }

    struct coordinate *coord = malloc(sizeof(struct coordinate));
    coord->x = x;
    coord->y = y;
    return coord;
}

struct instruction * parseInstruction(char *line) {
    if (strstr(line, "fold along ") == NULL) {
        return NULL;
    }
    const char *instr = line + 11;

    enum direction dir;
    if (*instr == 'x') {
        dir = X;
    } else {
        dir = Y;
    }

    char *endptr;
    uint32_t value = strtol(instr + 2, &endptr, 10);
    if (endptr == instr + 2) {
        return NULL;
    }

    struct instruction *result = malloc(sizeof(struct instruction));
    result->dir = dir;
    result->value = value;
    return result;
}

void readLines(FILE *file, char ***lines, uint32_t *lineCount) {
    if (file == NULL) {
        exit(1);
    }

    char *line = NULL;
    size_t len = 0;

    uint32_t i = 0;
    while (getline(&line, &len, file) != -1) {
        char *copy = (char *) malloc(sizeof(char) * len);
        memcpy(copy, line, len);
        appendString(lines, lineCount, i++, &copy);
        // Don't need to worry about line since it will be realloc'd on each call to getline
    }
    // We do need to clean this up though (append memcpy's it)
    free(line);

    truncateString(lines, lineCount, i);
}

void freeLines(char ***lines, const uint32_t lineCount) {
    uint32_t i;
    for (i = 0; i < lineCount; ++i) {
        free((*lines)[i]);
    }
    free(*lines);

    *lines = NULL;
}

inline uint32_t max(const uint32_t left, const uint32_t right) {
    return left > right ? left : right;
}

void printCoords(const struct coordinate *coords, const uint32_t coordCount) {
    uint32_t maxX = 0, maxY = 0;

    // Find dimensions
    uint32_t i, j, k;
    for (i = 0; i < coordCount; ++i) {
        struct coordinate c = coords[i];
        maxX = max(maxX, c.x + 1);
        maxY = max(maxY, c.y + 1);
    }

    for (j = 0; j < maxY; ++j) {
        for (i = 0; i < maxX; ++i) {
            for (k = 0; k < coordCount; ++k) {
                struct coordinate c = coords[k];
                if (c.x == i && c.y == j) {
                    printf("#");
                    goto endCoordLoop;
                }
            }

            printf(" ");

            endCoordLoop:;
        }
        printf("\n");
    }
}
