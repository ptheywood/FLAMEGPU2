#include <stdio.h>
#include "flamegpu/version.h"

int main(int argc, const char ** argv) {
    printf("flamegpu Version %s\n", flamegpu::VERSION_FULL);
    return 0;
}
