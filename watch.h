#ifndef WATCH_H
#define WATCH_H

#include <CoreServices/CoreServices.h>

void watch(const char *path, void (*callback)());

#endif
