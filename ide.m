#import <Cocoa/Cocoa.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "watch.h"

static lua_State *L;
static void interpreterInit() {
    L = luaL_newstate();
    luaL_openlibs(L);
}

static void interpreterRun() {
    luaL_dofile(L, "language.lua");
}

@interface IdeTextStorageDelegate: NSObject<NSTextStorageDelegate>
@end

@implementation IdeTextStorageDelegate
- (void)textStorage:(NSTextStorage *)textStorage 
  didProcessEditing:(NSTextStorageEditActions)editedMask 
              range:(NSRange)editedRange 
     changeInLength:(NSInteger)delta {
    id contents = [textStorage string];
    
}
@end

@interface IdeApplication: NSApplication
@end

@implementation IdeApplication
/* from https://stackoverflow.com/questions/970707/cocoa-keyboard-shortcuts-in-dialog-without-an-edit-menu
   hack around not having a real Edit menu => not having edit keyboard shortcuts */
- (void) sendEvent:(NSEvent *)event {
    if ([event type] == NSKeyDown) {
        if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
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
        else if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == (NSCommandKeyMask | NSShiftKeyMask)) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"Z"]) {
                if ([self sendAction:@selector(redo:) to:nil from:self])
                    return;
            }
        }
    }
    [super sendEvent:event];
}

// Blank Selectors to silence Xcode warnings: 'Undeclared selector undo:/redo:'
- (IBAction)undo:(id)sender {}
- (IBAction)redo:(id)sender {}
@end

int main() {
    interpreterInit();
    watch("language.lua", &interpreterRun);

    @autoreleasepool {
        [IdeApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        id applicationName = [[NSProcessInfo processInfo] processName];

        NSRect contentFrame = NSMakeRect(0, 0, 600, 600);
        id window = [[NSWindow alloc] initWithContentRect:contentFrame
                                                styleMask:NSTitledWindowMask
                                                  backing:NSBackingStoreBuffered defer:NO];

        id textView = [[NSTextView alloc] initWithFrame:contentFrame];
        id textStorageDelegate = [[IdeTextStorageDelegate alloc] init];
        [[textView textStorage] setDelegate:textStorageDelegate];
        [window setContentView:textView];
        [window makeFirstResponder:textView];

        [window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
        [window setTitle: applicationName];
        [window makeKeyAndOrderFront:nil];

        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return 0;
}

