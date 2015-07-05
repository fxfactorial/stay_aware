#import <Cocoa/Cocoa.h>

@interface OCamlNotifier : NSObject <NSUserNotificationCenterDelegate,
	                             NSApplicationDelegate>

-(void)do_notification:(NSString*)m;
-(NSImage*)load_image;

@end
