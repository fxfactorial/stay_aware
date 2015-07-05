#import <Cocoa/Cocoa.h>

@interface OCamlNotifier : NSObject <NSUserNotificationCenterDelegate>

-(void)do_notification:(NSString*)m;

@end
