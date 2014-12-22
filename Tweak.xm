#import <substrate.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>

#define NUMBER_OF_TAPS 2

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
    if (numTaps == NUMBER_OF_TAPS)
        lockDevice();
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
