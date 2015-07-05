#import <Cocoa/Cocoa.h>
#include "values.h"

@interface OCamlNotifier : NSObject <NSUserNotificationCenterDelegate,
	                             NSApplicationDelegate>

-(void)do_notification:(NSString*)m;
-(NSImage*)load_image:(ImageChoice)c;

@end
