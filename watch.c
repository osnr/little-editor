#include <CoreServices/CoreServices.h>
#include "watch.h"

static void callbackWrapper(
    ConstFSEventStreamRef streamRef,
    void *clientCallbackInfo,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[])
{
    char **paths = eventPaths;

    void (*callback)() = clientCallbackInfo;
    callback();
}

void watch(const char *path, void (*callback)()) {
    /* Define variables and create a CFArray object containing
       CFString objects containing paths to watch.
     */
    CFStringRef pathToWatch = CFStringCreateWithCString(kCFAllocatorDefault,
                                                        path,
                                                        kCFStringEncodingUTF8);
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&pathToWatch, 1, NULL);

    FSEventStreamContext context = {0};
    context.info = callback;

    FSEventStreamRef stream;
    CFAbsoluteTime latency = 0.05; /* Latency in seconds */
 
    /* Create the stream, passing in a callback */
    stream = FSEventStreamCreate(NULL,
        &callbackWrapper,
        &context,
        pathsToWatch,
        kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
        latency,
        kFSEventStreamCreateFlagFileEvents // special flag for tracking file events
    );

    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}
