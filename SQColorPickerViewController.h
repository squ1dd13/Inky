//
//  ViewController.h
//  StickAroundPrefs
//
//  Created by Alex Gallon on 24/07/2019.
//  Copyright © 2019 Squ1dd13. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Funcs.h"
#include "transparency.h"
@import QuartzCore;

@interface SQColorPickerViewController : UIViewController <UITextFieldDelegate> {
    int _updateCount;
}

//UITextFields are used over UILabels because UILabels flicker when the user drags the sliders and the text changes quickly.
//All UITextFields (bar hexTextField) were all UILabels at one point, hence the naming.
@property (strong, nonatomic) UITextField *hexTextField;
@property (strong, nonatomic) UILabel *colorNameLabel;
@property (nonatomic, readwrite, strong) NSDictionary *colorNames;
@property (strong, nonatomic) UISlider *redSlider;
@property (strong, nonatomic) UISlider *greenSlider;
@property (strong, nonatomic) UISlider *blueSlider;
@property (strong, nonatomic) UISlider *alphaSlider;
@property (strong, nonatomic) UILabel *rgbLabel;
@property (strong, nonatomic) UITextField *doneButton;
@property (strong, nonatomic) UIImageView *completeButton;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UILabel *previousColorLabel;
@property (nonatomic, copy) UIColor *chosenColor;
@property (nonatomic, copy) UIColor *originalStatusBarColor;
@property (nonatomic, assign, readwrite) NSString *defaultsKey;
@property (nonatomic, assign, readwrite) NSString *defaultsDomain;
@property (nonatomic, assign, readwrite) BOOL usesAlphaSlider;
@property (nonatomic, assign, readwrite) BOOL usesColorComparison;
-(id)initWithDefaultsKey:(NSString *)key domain:(NSString *)defaultsDomain defaultColor:(UIColor *)defaultColor;
@end
