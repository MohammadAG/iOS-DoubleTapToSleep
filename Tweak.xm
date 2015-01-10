#import <substrate.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>
#import <libactivator/libactivator.h>

#define NUMBER_OF_TAPS 2

@interface LockDeviceActivator : NSObject<LAListener>
@end

@interface DoubleTapEventSource: NSObject <LAEventDataSource>
@end

@interface SpringBoard : UIApplication
- (void)lockButtonUp:(__GSEvent *)event;
- (void)lockButtonDown:(__GSEvent *)event;
@end

static void lockDevice()
{
    SpringBoard *sb = (SpringBoard *) [UIApplication sharedApplication];
    __GSEvent* event = NULL;
    struct GSEventRecord record;
    memset(&record, 0, sizeof(record));
    
    record.timestamp = GSCurrentEventTimestamp();
    record.type = kGSEventLockButtonDown;
    
    event = GSEventCreateWithEventRecord(&record);
    [sb lockButtonDown:event];
    CFRelease(event);
    
    record.type = kGSEventLockButtonUp;
    
    event = GSEventCreateWithEventRecord(&record);
    [sb lockButtonUp:event];
    CFRelease(event);
}

static void handleTouches(NSSet *touches)
{
    NSUInteger numTaps = [[touches anyObject] tapCount];
    if (numTaps == NUMBER_OF_TAPS) {
        LAEvent *event = [LAEvent eventWithName:@"com.mohammadag.doubletaptosleep.emptyareaddoubletapped" mode:[LASharedActivator currentEventMode]];
        [LASharedActivator sendEventToListener:event];
    }
}

@implementation LockDeviceActivator

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    lockDevice();
    [event setHandled:YES];
}

+(void)load {
    @autoreleasepool {
        [[LAActivator sharedInstance] registerListener:[self new] forName:@"com.mohammadag.doubletaptosleep.lockdevice"];
    }
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Lock device";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Lock device as if the power button was pressed";
}
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}

@end

@implementation DoubleTapEventSource

static DoubleTapEventSource *myDataSource;

+ (void)load
{
    @autoreleasepool {
        myDataSource = [[DoubleTapEventSource alloc] init];
    }
}

- (id)init {
    if ((self = [super init])) {
        [LASharedActivator registerEventDataSource:self forEventName:@"com.mohammadag.doubletaptosleep.emptyareaddoubletapped"];
    }
    return self;
}

- (void)dealloc {
    [LASharedActivator unregisterEventDataSourceWithEventName:@"com.mohammadag.doubletaptosleep.emptyareaddoubletapped"];
    [super dealloc];
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
    return @"Empty area double tapped";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
    return @"An empty area (such as background) was double tapped";
}

- (NSString *)localizedGroupForEventName:(NSString *)eventName {
    return @"SpringBoard";
}

@end

%ctor {
    @autoreleasepool {
        LAEvent *event = [LAEvent eventWithName:@"com.mohammadag.doubletaptosleep.emptyareaddoubletapped" mode:LAEventModeSpringBoard];
        NSArray *array = [LASharedActivator assignedListenerNamesForEvent:event];
        if ([array count] == 0)
            [LASharedActivator assignEvent:event toListenerWithName:@"com.mohammadag.doubletaptosleep.lockdevice"];
        
        event = [LAEvent eventWithName:@"com.mohammadag.doubletaptosleep.emptyareaddoubletapped" mode:LAEventModeLockScreen];
        array = [LASharedActivator assignedListenerNamesForEvent:event];
        if ([array count] == 0)
            [LASharedActivator assignEvent:event toListenerWithName:@"com.mohammadag.doubletaptosleep.lockdevice"];
    }
}

%hook SBIconListView

%new
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    handleTouches(touches);
}

%end

%hook SBLockScreenScrollView

%new
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    handleTouches(touches);
}

%end
