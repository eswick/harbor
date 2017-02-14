
@interface SBUIIconForceTouchController : NSObject

+ (BOOL)_isPeekingOrShowing;

- (void)_presentAnimated:(BOOL)arg1 withCompletionHandler:(void(^)())arg2;
- (void)_setupWithGestureRecognizer:(id)arg1;

@end

@interface SBUIAppIconForceTouchController : NSObject

- (void)startHandlingGestureRecognizer:(id)arg1;

@end
