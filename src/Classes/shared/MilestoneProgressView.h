//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MilestoneProgressView : UIView
{
    UIView * progressView;
    UIView * remainingView;

    float progress;
}

@property (nonatomic, retain) UIColor * outlineColor;
@property (nonatomic, retain) UIColor * progressColor;
@property (nonatomic, retain) UIColor * remainingColor;

@property (nonatomic) float progress;

- (void)setOutlineColor:(UIColor *)color;
- (UIColor *)outlineColor;
- (void)setProgressColor:(UIColor *)color;
- (UIColor *)progressColor;
- (void)setRemainingColor:(UIColor *)color;
- (UIColor *)remainingColor;

@end