#import <Cocoa/Cocoa.h>

void recompile() {
    
}

@interface IdeTextStorageDelegate: NSObject<NSTextStorageDelegate>

@end

@implementation IdeTextStorageDelegate
- (void)textStorage:(NSTextStorage *)textStorage 
  didProcessEditing:(NSTextStorageEditActions)editedMask 
              range:(NSRange)editedRange 
     changeInLength:(NSInteger)delta {
    NSLog(@"hi");    
}
@end

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
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

