#import <Cocoa/Cocoa.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "watch.h"

static NSTextView *textView;

static lua_State *L;
static void interpreterInit() {
    L = luaL_newstate();
    luaL_openlibs(L);
}

static int l_setDefaultFont(lua_State *L) {
    NSString *fontName = [NSString stringWithUTF8String:luaL_checkstring(L, 1)];
    int fontSize = luaL_checknumber(L, 2);
    [textView setFont:[NSFont fontWithName:fontName size:fontSize]];
    return 0;
}

static void interpreterRun() {
    lua_pushcfunction(L, l_setDefaultFont);
    lua_setglobal(L, "setdefaultfont");

    luaL_dofile(L, "language.lua");
}

static void interpreterHook(const char *s) {
    lua_getglobal(L, "hook");
    if (lua_isfunction(L, -1)) {
        lua_pushstring(L, s);
        lua_pcall(L, 1, 0, 0);
    }
}

@interface IdeTextStorageDelegate: NSObject<NSTextStorageDelegate>
@end

@implementation IdeTextStorageDelegate
- (void)textStorage:(NSTextStorage *)textStorage 
  didProcessEditing:(NSTextStorageEditActions)editedMask 
              range:(NSRange)editedRange 
     changeInLength:(NSInteger)delta {
    id string = [textStorage string];
    interpreterHook([string UTF8String]);
}
@end

@interface IdeApplication: NSApplication
@end

@implementation IdeApplication
/* from https://stackoverflow.com/questions/970707/cocoa-keyboard-shortcuts-in-dialog-without-an-edit-menu
   hack around not having a real Edit menu => not having edit keyboard shortcuts */
- (void) sendEvent:(NSEvent *)event {
    if ([event type] == NSEventTypeKeyDown) {
        if (([event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask) == NSEventModifierFlagCommand) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
                if ([self sendAction:@selector(cut:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
                if ([self sendAction:@selector(copy:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
                if ([self sendAction:@selector(paste:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"z"]) {
                if ([self sendAction:@selector(undo:) to:nil from:self])
                    return;
            }
            else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
                if ([self sendAction:@selector(selectAll:) to:nil from:self])
                    return;
            }
        }
        else if (([event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask) == (NSEventModifierFlagCommand | NSEventModifierFlagShift)) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"Z"]) {
                if ([self sendAction:@selector(redo:) to:nil from:self])
                    return;
            }
        }
    }
    [super sendEvent:event];
}

// Blank selectors to silence Xcode warnings: 'Undeclared selector undo:/redo:'
- (IBAction)undo:(id)sender {}
- (IBAction)redo:(id)sender {}
@end

int main() {
    @autoreleasepool {
        [IdeApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        id applicationName = [[NSProcessInfo processInfo] processName];

        NSRect contentFrame = NSMakeRect(0, 0, 600, 600);
        id window = [[NSWindow alloc]
                        initWithContentRect:contentFrame
                                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskResizable | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                    backing:NSBackingStoreBuffered
                                      defer:NO];

        // from https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html#//apple_ref/doc/uid/20000938-164652
        NSScrollView *scrollView = [[NSScrollView alloc]
                                       initWithFrame:[[window contentView] frame]];
        NSSize contentSize = [scrollView contentSize];
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
        [textView setMinSize:NSMakeSize(0.0, contentSize.height)];
        [textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [textView setVerticallyResizable:YES];
        [textView setHorizontallyResizable:YES];
        [textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        // The order of the following 2 lines matters! WTF?
        [[textView textContainer] setWidthTracksTextView:NO];
        [[textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
 
        id textStorageDelegate = [[IdeTextStorageDelegate alloc] init];
        [[textView textStorage] setDelegate:textStorageDelegate];

        [scrollView setDocumentView:textView];
        [window setContentView:scrollView];
        [window makeFirstResponder:textView];

        [window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
        [window setTitle: applicationName];
        [window makeKeyAndOrderFront:nil];

        // Now that we have all the editor UI,
        // initialize and first-run the Lua script.
        interpreterInit();
        interpreterRun();

        // Set up a file-watcher that will rerun when the Lua script
        // changes. (It runs on the single main CF run loop on the
        // NSApp, I think, so no threading issues!)
        watch("language.lua", &interpreterRun);

        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return 0;
}

