#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#include "osx_notifier.h"

NSString *fake_bundle_identifier;

@implementation NSBundle(swizzle)
-(NSString *)__bundleIdentifier
{
	if (self == [NSBundle mainBundle]) {
		return fake_bundle_identifier ? fake_bundle_identifier :
			@"com.apple.finder";
	} else
		return [self __bundleIdentifier];
}
@end

BOOL install_bundle_hook()
{
	Class b_class = objc_getClass("NSBundle");
	if (b_class) {
		SEL current = @selector(bundleIdentifier);
		Method m1 = class_getInstanceMethod(b_class, current);
		current = @selector(__bundleIdentifier);
		Method m2 = class_getInstanceMethod(b_class, current);
		method_exchangeImplementations(m1, m2);
		return YES;
	}
	return NO;
}

@implementation OCamlNotifier

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

-(void)do_notification : (NSString*)message
{
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	[notification setTitle:message];
	[notification setInformativeText:@"I love PandaBar!"];
	[notification setSoundName:NSUserNotificationDefaultSoundName];
	NSUserNotificationCenter *center =
		[NSUserNotificationCenter defaultUserNotificationCenter];
	[center deliverNotification:notification];
	[[NSSound soundNamed:@"Hero"] play];
}

@end

void notify_start(char *message)
{
	if (install_bundle_hook()) {
		OCamlNotifier *carrier = [OCamlNotifier new];
		NSString *wrapped = [NSString stringWithCString:message
											   encoding:NSUTF8StringEncoding];
		[carrier do_notification:wrapped];
	}
	else
		NSLog(@"Error, wasn't able to do the bundle hook");
}
