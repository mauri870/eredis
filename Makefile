
REDIS_VERSION = 4.0.14
REDIS_URL = https://github.com/redis/redis/archive/refs/tags/$(REDIS_VERSION).tar.gz
ifeq ($(shell uname -s), Darwin)
DYLIB_SETUP=DYLD_LIBRARY_PATH=`pwd`/redis/src
else
DYLIB_SETUP=LD_LIBRARY_PATH=`pwd`/redis/src
EXTRA_LDFLAGS = -Wl,-rpath `pwd`/redis/src
endif

CC ?= gcc
CFLAGS = -O2 -g

all: eredis_test eredis_benchmark

clean:
	-rm -f eredis_test eredis_test.o

cleanall: clean
	-rm -rf redis

redis/src/liberedis.so: redis/.patched
	$(MAKE) -C redis embedded

redis/.patched:
	mkdir -p redis && \
	cd redis && \
	wget -qO- $(REDIS_URL) | tar -xz --strip-components=1 && \
	patch -p1 < ../eredis.diff && \
	sed -i 's/const char \*SDS_NOINIT;/extern const char *SDS_NOINIT;/' src/sds.h && \
	touch .patched

eredis_test: redis/src/liberedis.so eredis_test.o
	$(CC) eredis_test.o -o eredis_test -Lredis/src -leredis $(EXTRA_LDFLAGS) $(EXTRA_LIBS)

eredis_benchmark: redis/src/liberedis.so eredis_benchmark.o
	$(CC) eredis_benchmark.o -o eredis_benchmark -fPIE -Lredis/src -leredis $(EXTRA_LDFLAGS) $(EXTRA_LIBS)

tests: eredis_test
	$(DYLIB_SETUP) ./eredis_test

go-tests: redis/src/liberedis.so
	$(DYLIB_SETUP) go test -v ./golang/eredis

benchmark: eredis_benchmark
	$(DYLIB_SETUP) ./eredis_benchmark
