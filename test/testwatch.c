#include "watch.h"

void callback() {
    printf("change\n");
}

int main() {
    watch("../language.lua", &callback);

    CFRunLoopRun();
}
