
define c-objs # args: $1 = dir, $2 = source files
$1/%.dyn_o: $1/%.c
	$$(QCC) $$(MY_CFLAGS) -fPIC -o $$@ -c $$<
$1/%.o: $1/%.c
	$$(QCC) $$(MY_CFLAGS) -o $$@ -c $$<
STATIC_OBJS+=$$(patsubst %.c,$1/%.o,$2)
DYNAMIC_OBJS+=$$(patsubst %.c,$1/%.dyn_o,$2)
endef

define test # args: $1 = dir, $2 = source file names
$1/%.t: $1/%.o
	$$(QLINK) $$(MY_CFLAGS) -o $$@ $$<
$1/%.o: $1/%.c amalg-src
	$$(QCC) $$(MY_CFLAGS) -o $$@ -c $$<

$1/%.frama_c.txt: $1/%.c amalg-src
	$$(QFRAMAC) -val -no-val-show-progress -machdep x86_64 \
	-obviously-terminates -cpp-extra-args="$$(MY_INCLUDES)" $$< \
	| (egrep -i "(user error|assert)" > $$@; test "$$$$?" -eq 1)

TEST_OBJS+=$$(patsubst %,$1/%.o,$2)
TEST_EXES+=$$(patsubst %,$1/%.t,$2)
FRAMAC_ANALYSIS+=$$(patsubst %,$1/%.frama_c.txt,$2)

.INTERMEDIATE: $$(patsubst %,$1/%.o,$2)
endef
