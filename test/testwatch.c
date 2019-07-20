#include "watch.h"

void callback() {
    printf("change\n");
}

int main() {
    watch("../editor.lua", &callback);

    CFRunLoopRun();
}
