#import <objc/runtime.h>

#import "UIView+Origin.h"

#import "SBIconListModel.h"
#import "SBDockIconListView.h"
#import "SBIconView.h"
#import "SBIconViewMap.h"
#import "SBIconController.h"
#import "SBIcon.h"
#import "SBScaleIconZoomAnimator.h"
#import "SBWallpaperEffectView.h"
#import "SBUIAnimationZoomUpAppFromHome.h"
#import "SBIconFadeAnimator.h"

#pragma mark Declarations

@interface SBDockIconListView ()

@property (nonatomic, assign) CGFloat focusPoint;
@property (nonatomic, assign) BOOL trackingTouch;
@property (nonatomic, assign) SBIconView *activatingIcon;

@property (nonatomic, assign) CGFloat maxTranslationX;
@property (nonatomic, assign) CGFloat xTranslationDamper;

@property (nonatomic, retain) UIView *indicatorView;
@property (nonatomic, assign) UILabel *indicatorLabel;
@property (nonatomic, assign) SBIconView *focusedIconView;

@new
- (CGFloat)horizontalIconBounds;
- (CGFloat)collapsedIconScale;
- (CGFloat)collapsedIconWidth;
- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset;
- (CGFloat)yTranslationForOffsetFromFocusPoint:(CGFloat)offset;
- (CGFloat)xTranslationForOffsetFromFocusPoint:(CGFloat)offset;
- (NSUInteger)columnAtX:(CGFloat)x;

- (void)updateIconTransforms;
- (void)collapseAnimated:(BOOL)animated;
- (void)updateIndicatorForIconView:(SBIconView*)iconView animated:(BOOL)animated;

@end

#pragma mark Constants

static const CGFloat kHorizontalIconInset = 15.0;
static const CGFloat kCancelGestureRange = 10.0;

static const CGFloat kEffectiveRange = 60.0;
static const CGFloat kMaxScale = 1.0;

#pragma mark -

@hook SBDockIconListView

@synthesize focusPoint;
@synthesize trackingTouch;
@synthesize activatingIcon;

@synthesize maxTranslationX;
@synthesize xTranslationDamper;

@synthesize indicatorView;
@synthesize indicatorLabel;
@synthesize focusedIconView;

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1{
	return 100;
}

- (id)initWithModel:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 {
	self = @orig(arg1, arg2, arg3);
	if (self) {

		// Set up indicator view
		self.indicatorView = [[UIView alloc] init];

		self.indicatorView.clipsToBounds = true;
		self.indicatorView.layer.cornerRadius = 5;

		// Add background view
		SBWallpaperEffectView *indicatorBackgroundView = [[objc_getClass("SBWallpaperEffectView") alloc] initWithWallpaperVariant:1];
		indicatorBackgroundView.style = 11;
		indicatorBackgroundView.translatesAutoresizingMaskIntoConstraints = false;

		[self.indicatorView addSubview:indicatorBackgroundView];
		[indicatorBackgroundView release];

		// Set up label
		UILabel *indicatorLabel = [[UILabel alloc] init];
		indicatorLabel.font = [UIFont systemFontOfSize:14];
		indicatorLabel.textColor = [UIColor whiteColor];
		indicatorLabel.textAlignment = NSTextAlignmentCenter;
		[self.indicatorView addSubview:indicatorLabel];
		self.indicatorLabel = indicatorLabel;

		[indicatorLabel release];

		// Setup constraints
		NSMutableArray *constraints = [NSMutableArray new];

		[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[v]-0-|" options:0 metrics:nil views: @{ @"v" : indicatorBackgroundView }]];
		[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[v]-0-|" options:0 metrics:nil views: @{ @"v" : indicatorBackgroundView }]];
		[self.indicatorView addConstraints:constraints];

		[constraints release];

		// -

		[self addSubview:self.indicatorView];
		[self.indicatorView release];

	}
	return self;
}

- (void)showIconImagesFromColumn:(NSInteger)arg1 toColumn:(NSInteger)arg2 totalColumns:(NSInteger)arg3 allowAnimations:(BOOL)arg4 {
	@orig(arg1, arg2, arg3, arg4);
}

#pragma mark Layout


- (CGFloat)horizontalIconBounds {
	return self.bounds.size.width - kHorizontalIconInset * 2;
}


- (CGFloat)collapsedIconScale {
	CGFloat normalIconSize = [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;

	CGFloat newIconSize = [self horizontalIconBounds] / self.model.numberOfIcons;

	if (self.model.numberOfIcons == 0) {
		return 1;
	}

	return MIN(newIconSize / normalIconSize, 1);
}


- (CGFloat)collapsedIconWidth {
	return [self collapsedIconScale] * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;
}


- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset {

	if (fabs(offset) > kEffectiveRange)
		return [self collapsedIconScale];

	return MAX((cos(offset / ((kEffectiveRange) / M_PI)) + 1.0) / (1.0 / (kMaxScale / 2.0)), [self collapsedIconScale]);
}


- (CGFloat)xTranslationForOffsetFromFocusPoint:(CGFloat)offset {

	if (self.xTranslationDamper == 0)
		self.xTranslationDamper = 1;

	return -(atan(offset / (self.xTranslationDamper * (M_PI / 4))) * ((self.maxTranslationX) / (M_PI / 2)));
}


- (CGFloat)yTranslationForOffsetFromFocusPoint:(CGFloat)offset {
	CGFloat evasionDistance = [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;

	if (fabs(offset) > kEffectiveRange)
		return 0;

	return -((cos(offset / ((kEffectiveRange) / M_PI)) + 1.0) / (1.0 / (evasionDistance / 2.0)));
}

- (void)updateEditingStateAnimated:(BOOL)arg1 {
	@orig(arg1);
	[self layoutIconsIfNeeded:0.0 domino:false];
}

- (void)layoutIconsIfNeeded:(NSTimeInterval)animationDuration domino:(BOOL)arg2 {
	
	CGFloat defaultWidth = [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;

	self.xTranslationDamper = acos((kEffectiveRange * [self collapsedIconScale]) / (kEffectiveRange / 2) - 1) * (kEffectiveRange / M_PI);
	self.maxTranslationX = 0;

	// Calculate total X translation

	int iconsInRange = (int)floor(kEffectiveRange / [self collapsedIconWidth]);
	float offset = 0;

	for (int i = 0; i < 2; i++) {
		// Run twice, once for left side of focus, and one for right side of focus

		for (int i = 0; i < iconsInRange; i++) {
			self.maxTranslationX += ([self scaleForOffsetFromFocusPoint:offset] * defaultWidth) - [self collapsedIconWidth];
			offset += [self collapsedIconWidth];
		}

		offset = [self collapsedIconWidth]; // Set to collapsed icon width, so we skip the center icon on the second run
	}

	CGFloat xOffset = MAX(([self horizontalIconBounds] - self.model.numberOfIcons * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width) / 2, 0);

	[UIView animateWithDuration:animationDuration animations:^{
		for (int i = 0; i < self.model.numberOfIcons; i++) {

			SBIcon *icon = self.model.icons[i];
			SBIconView *iconView = [self.viewMap mappedIconViewForIcon:icon];

			iconView.location = [self iconLocation];

			CGPoint center = CGPointZero;
			center.x = xOffset + ([self collapsedIconWidth] * i) + ([self collapsedIconWidth] / 2) + (self.bounds.size.width - [self horizontalIconBounds]) / 2;
			center.y = self.bounds.size.height / 2;

			iconView.center = center;
		}

		[self updateIconTransforms];
	}];
}


- (void)updateIconTransforms {

	for (int i = 0; i < self.model.numberOfIcons; i++) {
		SBIcon *icon = self.model.icons[i];
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:icon];

		const CGFloat offsetFromFocusPoint = self.focusPoint - iconView.center.x;


		CGFloat scale = [self collapsedIconScale];

		CGFloat tx = 0;
		CGFloat ty = 0;

		if (self.trackingTouch) {
			scale = [self scaleForOffsetFromFocusPoint:offsetFromFocusPoint];
			ty = [self yTranslationForOffsetFromFocusPoint:offsetFromFocusPoint];
			tx = [self xTranslationForOffsetFromFocusPoint:offsetFromFocusPoint];
		}


		iconView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeTranslation(tx, ty));
	}

}


- (void)updateIndicatorForIconView:(SBIconView*)iconView animated:(BOOL)animated {

	if (!iconView) {

		if (animated) {
			[UIView animateWithDuration:0.2 animations:^{
				self.indicatorView.alpha = 0;
			} completion:^(BOOL finished) {
				self.indicatorView.hidden = true;
				self.indicatorView.alpha = 1;
			}];
		}else{
			self.indicatorView.hidden = true;
		}

		return;
	}else{
		if (animated && self.indicatorView.hidden) {
			self.indicatorView.alpha = 0;
			self.indicatorView.hidden = false;

			[UIView animateWithDuration:0.2 animations:^{
				self.indicatorView.alpha = 1;
			} completion:nil];
		}else{
			self.indicatorView.hidden = false;
		}
	}

	void (^animations) (void) = ^{

		NSString *text = iconView.icon.displayName;
		CGFloat evasionDistance = [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;
		CGRect textRect = [text boundingRectWithSize:[objc_getClass("SBIconView") maxLabelSize] options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]} context:nil];

		self.indicatorView.bounds = CGRectMake(0, 0, textRect.size.width + 30, textRect.size.height + 30);
		self.indicatorView.center = CGPointMake(MAX(MIN(iconView.center.x, self.bounds.size.width - self.indicatorView.bounds.size.width / 2), self.indicatorView.bounds.size.width / 2), (self.bounds.size.height / 2) - evasionDistance - self.indicatorView.bounds.size.height - 20.0);

		self.indicatorLabel.text = text;
		self.indicatorLabel.bounds = textRect;
		self.indicatorLabel.center = CGPointMake(self.indicatorView.bounds.size.width / 2, self.indicatorView.bounds.size.height / 2);

	};

	if (animated)
		[UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:animations completion:nil];
	else
		animations();
}

#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	self.trackingTouch = true;
	self.focusPoint = [[touches anyObject] locationInView:self].x;
	self.activatingIcon = nil;

	[self layoutIconsIfNeeded:0.25 domino:false];

	// Update indicator
	SBIconView *focusedIcon = nil;

	@try {
		focusedIcon = [self.viewMap mappedIconViewForIcon:self.model.icons[[self columnAtX:self.focusPoint]]];
	}@catch (NSException *exception) { }

	[self updateIndicatorForIconView:focusedIcon animated:false];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	SBIconView *iconView = nil;

	@try {
		iconView = [self.viewMap mappedIconViewForIcon:self.model.icons[[self columnAtX:self.focusPoint]]];
	} @catch (NSException *e) { }

	if ([[touches anyObject] locationInView:self].y < 0 && ![[objc_getClass("SBIconController") sharedInstance] grabbedIcon] && iconView) {

		// get origin, remove transform, restore origin
		CGPoint origin = iconView.origin;
		iconView.transform = CGAffineTransformIdentity;
		iconView.origin = origin;

		// fix frame (somewhere along the way, the size gets set to zero. not exactly sure where)
		CGRect frame = iconView.frame;
		frame.size = [objc_getClass("SBIconView") defaultIconSize];
		iconView.frame = frame;

		// set grabbed and begin forwarding touches to icon
		[[objc_getClass("SBIconController") sharedInstance] setGrabbedIcon:iconView.icon];
		[iconView touchesBegan:touches withEvent:nil];
		[iconView longPressTimerFired];

		[self updateIndicatorForIconView:nil animated:true];

		return;
	}

	if ([[objc_getClass("SBIconController") sharedInstance] grabbedIcon]) {
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:[[objc_getClass("SBIconController") sharedInstance] grabbedIcon]];
		[iconView touchesMoved:touches withEvent:nil];
		return;
	}

	self.focusPoint = [[touches anyObject] locationInView:self].x;
	[self layoutIconsIfNeeded:0 domino:false];

	// Update indicator
	SBIconView *focusedIcon = nil;

	@try {
		focusedIcon = [self.viewMap mappedIconViewForIcon:self.model.icons[[self columnAtX:self.focusPoint]]];
	}@catch (NSException *exception) { }

	[self updateIndicatorForIconView:focusedIcon animated:true];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {


	if ([[objc_getClass("SBIconController") sharedInstance] grabbedIcon]) {
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:[[objc_getClass("SBIconController") sharedInstance] grabbedIcon]];
		[iconView touchesEnded:touches withEvent:nil];
		return;
	}

	[self updateIndicatorForIconView:nil animated:true];

	if([[touches anyObject] locationInView:self].y > self.bounds.size.height - kCancelGestureRange) {
		// User swiped off to the bottom edge of the screen; collapse and do nothing
		[self collapseAnimated:true];
		return;
	}

	NSInteger index = [self columnAtX:self.focusPoint];

	SBIconView *iconView = nil;

	@try {
		iconView = [self.viewMap mappedIconViewForIcon:self.model.icons[index]];
	}@catch (NSException *e) {
		[self collapseAnimated:true];
		return;
	}

	[self bringSubviewToFront:iconView];

	self.activatingIcon = iconView;
	self.focusPoint = iconView.center.x;

	[self layoutIconsIfNeeded:0.2 domino:false];

	[[objc_getClass("SBIconController") sharedInstance] iconTapped:iconView];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	self.trackingTouch = false;
	[self layoutIconsIfNeeded:0 domino:false];
}

#pragma mark -


- (void)collapseAnimated:(BOOL)animated {
	self.trackingTouch = false;
	self.activatingIcon = nil;
	[self layoutIconsIfNeeded:animated ? 0.25 : 0.0 domino:false];
}


- (NSUInteger)columnAtX:(CGFloat)x {
	return [self columnAtPoint:CGPointMake(x, 0)];
}

- (NSUInteger)columnAtPoint:(struct CGPoint)arg1 {
	CGFloat collapsedItemWidth = [self collapsedIconScale] * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;
	CGFloat xOffset = MAX(([self horizontalIconBounds] - self.model.numberOfIcons * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width) / 2, 0);

	NSUInteger index = floorf((arg1.x - (self.bounds.size.width - [self horizontalIconBounds]) / 2 - xOffset) / collapsedItemWidth);

	return index;
}

- (void)removeIconAtIndex:(NSUInteger)arg1 {
	@orig(arg1);
	[self collapseAnimated:true];
}

@end

#pragma mark Animators

@hook SBIconFadeAnimator

- (void)_cleanupAnimation {
	@orig();
	[[[objc_getClass("SBIconController") sharedInstance] dockListView] collapseAnimated:true];
}

@end

@hook SBScaleIconZoomAnimator

- (void)enumerateIconsAndIconViewsWithHandler:(void (^) (id animator, SBIconView *iconView, BOOL inDock))arg1 {
	// Prevent this method from changing the origins and transforms of the dock icons
}

- (void)_prepareAnimation {
	// Focus dock on animation target icon

	SBDockIconListView *dockListView = [[objc_getClass("SBIconController") sharedInstance] dockListView];
	SBIconView *targetIconView = [dockListView.viewMap mappedIconViewForIcon:self.targetIcon];

	if ([targetIconView isInDock]) {
		dockListView.activatingIcon = targetIconView;
		dockListView.focusPoint = targetIconView.center.x;
		dockListView.trackingTouch = true;
		[dockListView layoutIconsIfNeeded:0.0 domino:false];
	}

	@orig();
}

- (void)_cleanupAnimation {
	@orig();
	[self.dockListView collapseAnimated:true];
}

@end
