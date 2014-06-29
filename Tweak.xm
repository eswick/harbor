#import "UIView+Origin.h"

#import "SBIconListModel.h"
#import "SBDockIconListView.h"
#import "SBIconView.h"
#import "SBIconViewMap.h"
#import "SBIconController.h"
#import "SBIcon.h"
#import "SBScaleIconZoomAnimator.h"

@interface SBDockIconListView ()

@property (nonatomic, assign) CGFloat focusPoint;
@property (nonatomic, assign) BOOL trackingTouch;
@property (nonatomic, assign) SBIconView *activatingIcon;

- (CGFloat)collapsedIconScale;
- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset;
- (CGFloat)yTranslationForOffsetFromFocusPoint:(CGFloat)offset;
- (void)didAnimateZoomUp;
- (void)didAnimateZoomDown;
- (void)collapseAnimated:(BOOL)animated;
- (CGFloat)collapsedIconWidth;
- (void)updateIconTransforms;

@end

%hook SBDockIconListView

%property (nonatomic, retain) CGFloat focusPoint;
%property (nonatomic, retain) BOOL trackingTouch;
%property (nonatomic, assign) SBIconView *activatingIcon;

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1{
	return 100;
}

- (id)initWithModel:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 {
	self = %orig;
	if (self) {

	}
	return self;
}

- (void)showIconImagesFromColumn:(NSInteger)arg1 toColumn:(NSInteger)arg2 totalColumns:(NSInteger)arg3 allowAnimations:(BOOL)arg4 {
	%orig;
}

#pragma mark Layout

%new
- (CGFloat)collapsedIconScale {
	CGFloat normalIconSize = [%c(SBIconView) defaultVisibleIconImageSize].width;

	CGFloat newIconSize = self.bounds.size.width / self.model.numberOfIcons;

	return MIN(newIconSize / normalIconSize, 1);
}

%new
- (CGFloat)collapsedIconWidth {
	return [self collapsedIconScale] * [%c(SBIconView) defaultVisibleIconImageSize].width;
}

#define EXPANSION_NEIGHBORS 3

%new
- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset {
	CGSize defaultSize = [%c(SBIconView) defaultVisibleIconImageSize];

	CGFloat normalizedOffset = fabsf(offset / (defaultSize.width * [self collapsedIconScale]));
	CGFloat scalar = 0.0;

	if (normalizedOffset <= 0.5) {
		scalar = 1.0;
	} else if (normalizedOffset < (EXPANSION_NEIGHBORS + 0.5)) {
		scalar = ((EXPANSION_NEIGHBORS + 0.5) - normalizedOffset) / EXPANSION_NEIGHBORS;
	}

	CGFloat scaledHeight = defaultSize.width * scalar + (defaultSize.width * [self collapsedIconScale]) * (1.0 - scalar);
	return scaledHeight / defaultSize.width;
}

static const CGFloat FingerTranslationRadius = 50.0;
static const CGFloat FingerTranslation = 75.0;

%new
- (CGFloat)yTranslationForOffsetFromFocusPoint:(CGFloat)offset {

	if (fabs(offset) > FingerTranslationRadius )
		return 0;

	return -((cos(offset / ((FingerTranslationRadius) / M_PI)) + 1) / ( 1 / (FingerTranslation / 2)));
}

- (void)layoutIconsIfNeeded:(NSTimeInterval)animationDuration domino:(BOOL)arg2 {
	
	[UIView animateWithDuration:animationDuration animations:^{
		for (int i = 0; i < self.model.numberOfIcons; i++) {

			SBIcon *icon = self.model.icons[i];
			SBIconView *iconView = [self.viewMap mappedIconViewForIcon:icon];

			CGPoint center = CGPointZero;

			center.x = ([self collapsedIconWidth] * i) + [self collapsedIconWidth] / 2;
			center.y = self.bounds.size.height / 2;

			iconView.center = center;

			iconView.labelHidden = true;

		}

		[self updateIconTransforms];
	}];
}

%new
- (void)updateIconTransforms {

	CGFloat expansionSurplus = 0;

	for (int i = -EXPANSION_NEIGHBORS - 1; i < EXPANSION_NEIGHBORS + 1; i++) {
		expansionSurplus += [self scaleForOffsetFromFocusPoint:i * [self collapsedIconWidth]] * [%c(SBIconView) defaultVisibleIconImageSize].width - [self collapsedIconWidth];
	}

	CGFloat origin = -(expansionSurplus / 2);

	for (int i = 0; i < self.model.numberOfIcons; i++) {
		SBIcon *icon = self.model.icons[i];
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:icon];

		iconView.location = [self iconLocation];

		const CGFloat offsetFromFocusPoint = self.focusPoint - iconView.center.x;


		CGFloat scale = [self collapsedIconScale];
		CGFloat tx = 0;
		CGFloat ty = 0;

		if (self.trackingTouch) {
			scale = [self scaleForOffsetFromFocusPoint:offsetFromFocusPoint];
			ty = [self yTranslationForOffsetFromFocusPoint:offsetFromFocusPoint];


			CGFloat width = [%c(SBIconView) defaultVisibleIconImageSize].width * scale;

			tx = origin - (iconView.center.x - width / 2);
			origin += width;
		}


		iconView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(tx, ty));


	}

}

#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	self.trackingTouch = true;
	self.focusPoint = [[touches anyObject] locationInView:self].x;
	self.activatingIcon = nil;

	[self layoutIconsIfNeeded:0.25 domino:false];	
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	if ([[touches anyObject] locationInView:self].y < 0 && ![[%c(SBIconController) sharedInstance] grabbedIcon]) {
		CGFloat collapsedItemWidth = [self collapsedIconScale] * [%c(SBIconView) defaultVisibleIconImageSize].width;
		NSInteger index = floorf((self.focusPoint) / collapsedItemWidth);

		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:self.model.icons[index]];

		

		// get origin, remove transform, restore origin
		CGPoint origin = iconView.origin;
		iconView.transform = CGAffineTransformIdentity;
		iconView.origin = origin;

		// fix frame (somewhere along the way, the size gets set to zero. not exactly sure where)
		CGRect frame = iconView.frame;
		frame.size = [%c(SBIconView) defaultIconSize];
		iconView.frame = frame;

		// set icon label visible
		iconView.labelHidden = false;

		// set grabbed and begin forwarding touches to icon
		[[%c(SBIconController) sharedInstance] setGrabbedIcon:iconView.icon];
		[iconView touchesBegan:touches withEvent:nil];
		[iconView longPressTimerFired];

		return;
	}

	if ([[%c(SBIconController) sharedInstance] grabbedIcon]) {
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:[[%c(SBIconController) sharedInstance] grabbedIcon]];
		[iconView touchesMoved:touches withEvent:nil];
		return;
	}

	self.focusPoint = [[touches anyObject] locationInView:self].x;
	[self layoutIconsIfNeeded:0 domino:false];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {


	if ([[%c(SBIconController) sharedInstance] grabbedIcon]) {
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:[[%c(SBIconController) sharedInstance] grabbedIcon]];
		[iconView touchesEnded:touches withEvent:nil];
		return;
	}

	CGFloat collapsedItemWidth = [self collapsedIconScale] * [%c(SBIconView) defaultVisibleIconImageSize].width;
	NSInteger index = floorf((self.focusPoint) / collapsedItemWidth);

	if (index > self.model.numberOfIcons - 1) {
		// No icon at this position
		return;
	}

	SBIconView *iconView = [self.viewMap mappedIconViewForIcon:self.model.icons[index]];

	self.activatingIcon = iconView;

	[[%c(SBIconController) sharedInstance] iconTapped:iconView];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	self.trackingTouch = false;
	[self layoutIconsIfNeeded:0 domino:false];
}

%new
- (void)collapseAnimated:(BOOL)animated {
	self.trackingTouch = false;
	self.activatingIcon = nil;
	[self layoutIconsIfNeeded:animated ? 0.25 : 0.0 domino:false];
}

%new
- (void)didAnimateZoomUp {

}

%new
- (void)didAnimateZoomDown {
	[self collapseAnimated:true];
}

- (NSUInteger)columnAtPoint:(struct CGPoint)arg1 {
	CGFloat collapsedItemWidth = [self collapsedIconScale] * [%c(SBIconView) defaultVisibleIconImageSize].width;
	NSUInteger index = floorf(arg1.x / collapsedItemWidth);

	return index;
}

- (void)removeIconAtIndex:(unsigned long)arg1 {
	%orig;
	[self collapseAnimated:true];
}

%end

%hook SBScaleIconZoomAnimator

- (void)enumerateIconsAndIconViewsWithHandler:(void (^) (id animator, SBIconView *iconView, BOOL inDock))arg1 {
	// Prevent this method from changing the origins and transforms of the dock icons
}

- (void)_animateToFraction:(CGFloat)arg1 afterDelay:(NSTimeInterval)arg2 withSharedCompletion:(void (^) (void))arg3 {

	void (^completionBlock) (void) = ^{

		if (arg1 == 1) {
			[self.dockListView didAnimateZoomUp];
		}else if (arg1 == 0) {
			[self.dockListView didAnimateZoomDown];
		}

		arg3();
	};

	%orig(arg1, arg2, completionBlock);

}

%end