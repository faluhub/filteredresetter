#include "cubiomes/finders.h"
#include "cubiomes/generator.h"
#include "cubiomes/layers.h"
#include "cubiomes/util.h"
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

uint64_t gen_seed(uint64_t start) {
    Pos pos;
    Pos pos1;

    Generator g;
    setupGenerator(&g, MC_1_16, 0);

    uint64_t seed = start;
    for (; ; seed++) {
        applySeed(&g, 0, seed);

        Pos spawn = estimateSpawn(&g);
        int rx = spawn.x / 16;
        int rz = spawn.z / 16;

        for (int i = -2; i <= 2; i++) {
            for (int j = -2; j <= 2; j++) {
                int cx = rx + i;
                int cz = rz + j;

                if (getStructurePos(Treasure, MC_1_16, seed, cx, cz, &pos)) {
                    if (isViableStructurePos(Treasure, &g, pos.x, pos.z, 0)) {
                        return seed;
                    }
                }
            }
        }

        if (getStructurePos(Shipwreck, MC_1_16, seed, 0, 0, &pos1)) {
            if (isViableStructurePos(Shipwreck, &g, pos1.x, pos1.z, 0)) {
                int x1 = spawn.x;
                int x2 = pos1.x;
                int z1 = spawn.z;
                int z2 = pos1.z;
                double calc = sqrt((x2 - x1) * (x2 - x1) + (z2 - z1) * (z2 - z1));
                if ((calc > 0 && calc < 100) || (calc < 0 && calc > -100)) {
                    return seed;
                }
            }
        }
    }
}

uint64_t rand_x;
uint64_t rand_iter() {
    rand_x ^= (rand_x << 7);
    rand_x ^= (rand_x >> 2);
    rand_x ^= (rand_x << 3);
    return rand_x;
}

int main() {
    FILE *file;
    uint64_t seed;
    int found = 0;

    srand(time(NULL));
    rand_x = rand();
    rand_iter();

    while (found != 5) {
        seed = gen_seed(rand_iter());
        found++;
    }

    file = fopen("./seed.txt", "w");
    fprintf(file, "%" PRId64, seed);
    fclose(file);

    return 0;
}
