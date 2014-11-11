#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_7_1
#define kCFCoreFoundationVersionNumber_iOS_7_1 847.26
#endif

#include "IOPowerSources.h"
#include "IOPSKeys.h"

@interface _UIBatteryBarLineView : UIView
@end

@implementation _UIBatteryBarLineView
@end

@interface _UILegibilityImageSet
+(id)imageFromImage:(id)image withShadowImage:(id)shadow;
@end

@interface UIStatusBarItemView : UIView
@end

@interface UIStatusBarBatteryItemView : UIStatusBarItemView
-(id)_accessoryImage;
-(BOOL)_needsAccessoryImage;
@end

double batteryLevel() {
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	CFArrayRef sources = IOPSCopyPowerSourcesList(blob);

	CFDictionaryRef pSource = NULL;
	const void *psValue;

	int numOfSources = CFArrayGetCount(sources);
	if (numOfSources == 0) {
		return -1.0f;
	}

	for (int i = 0 ; i < numOfSources ; i++)
	{
		pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
		if (!pSource) {
			return -1.0f;
		}
		psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));

		int curCapacity = 0;
		int maxCapacity = 0;

		psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
		CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);

		psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
		CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);

		if (maxCapacity != 0) {
			return (double)curCapacity / (double)maxCapacity;
		}
	}

	return -1.0f;
}

%hook UIStatusBarBatteryItemView
-(id)contentsImage {
	if ([self _needsAccessoryImage]) {
		UIImage* accessoryImage = [self _accessoryImage];

		UIGraphicsBeginImageContextWithOptions(accessoryImage.size, NO, 0.0);
		UIImage* blankImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		return [_UILegibilityImageSet imageFromImage:blankImage withShadowImage:blankImage];
	} else {
		return nil;
	}
}
%end

%hook UIStatusBarLayoutManager
-(id)_viewForItem:(id)item {
	id view = %orig;

	if ([view isKindOfClass:[%c(UIStatusBarBatteryItemView) class]]) {
		double capacity = batteryLevel();
		if (capacity < 0) {
			int capacityPercentage = MSHookIvar<int>(view, "_capacity");
			capacity = (double)capacityPercentage / 100.0;
		}

		UIView* foregroundView = MSHookIvar<UIView*>(self, "_foregroundView");

		CGRect bounds = [foregroundView bounds];
		float barWidth = bounds.size.width * capacity;

		CGRect barRect = CGRectMake(bounds.origin.x, bounds.origin.y, barWidth, 2);
		_UIBatteryBarLineView* lineView = [[_UIBatteryBarLineView alloc] initWithFrame:barRect];

		float red = 1.0;
		float green = 1.0;

		if (capacity > 0.5) {
			red = ((1.0 - capacity) / 0.5) * 204.0 / 255.0;
		} else {
			green = (capacity / 0.5) * 204.0 / 255.0;
		}

		UIColor* barColor = [UIColor colorWithRed:red green:green blue:0.0 alpha:1.0];
		lineView.backgroundColor = barColor;

		for (UIView* v in foregroundView.subviews) {
			if ([v isKindOfClass:[_UIBatteryBarLineView class]]) {
				[v removeFromSuperview];
				break;
			}
		}

		[foregroundView addSubview:lineView];
		[lineView release];
	}

	return view;
}

%group Hooks_7_0
-(double)_positionAfterPlacingItemView:(id)view startPosition:(double)start {
	double position = %orig;

	if ([view isKindOfClass:[%c(UIStatusBarBatteryItemView) class]]) {
		UIView* v = (UIView*)view;
		if (v.frame.size.width == 0) {
			position = start;
		}
	}

	return position;
}
%end

%group Hooks_7_1
-(double)_positionAfterPlacingItemView:(id)view startPosition:(double)start firstView:(BOOL)first {
	double position = %orig;

	if ([view isKindOfClass:[%c(UIStatusBarBatteryItemView) class]]) {
		UIView* v = (UIView*)view;
		if (v.frame.size.width == 0) {
			position = start;
		}
	}

	return position;
}
%end
%end

%ctor {
	%init;

	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_1) {
		%init(Hooks_7_1);
	} else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
		%init(Hooks_7_0);
	}
}

