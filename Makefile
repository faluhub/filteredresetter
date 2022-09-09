FILES = finder.c \
		cubiomes/biome_tree.c \
		cubiomes/finders.c \
		cubiomes/generator.c \
		cubiomes/layers.c \
		cubiomes/noise.c \
		cubiomes/util.c

finder:
	gcc -lm -O3 -o out/filter -I cubiomes $(FILES) $(CFLAGS)
