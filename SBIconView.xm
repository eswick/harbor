#import "SBIconView.h"
#import "SBIconController.h"

%hook SBIconView

#define super(...) ({ struct objc_super superInfo = { self, [UIView class] }; objc_msgSendSuper(&superInfo, _cmd, __VA_ARGS__); })

- (void)touchesEnded:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}

%end
