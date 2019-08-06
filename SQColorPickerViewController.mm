#include "SQColorPickerViewController.h"
#include "names.h"
#include <iostream>
#include <fstream>
#include <sys/stat.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#import <os/log.h>

@interface _UILabelLayer : CALayer
-(void)setContentsMultiplyColor:(CGColorRef)color;
@end

@interface SQColorPickerViewController ()

@end

@implementation SQColorPickerViewController

-(id)initWithDefaultsKey:(NSString *)key domain:(NSString *)defaultsDomain defaultColor:(UIColor *)defaultColor {
    self = [super init];
    if(self) {
        self.originalStatusBarColor = [[UIApplication sharedApplication] valueForKeyPath:@"_statusBar.foregroundColor"];

        //Check if the colour map has been written to a file yet.
        if(access("/var/mobile/Library/Application Support/Inky/ColourMap.plist", F_OK) == -1) {
            //Nope. We need to create it.
            mkdir("/var/mobile/Library/Application Support/Inky", 0755);
            std::ofstream mapFile("/var/mobile/Library/Application Support/Inky/ColourMap.plist", std::ios::binary);
            mapFile.write(reinterpret_cast<const char *>(colorMap), colorMapLength);
            mapFile.close();
        }

        //Load the map.
        self.colorNames = loadColorNames(@"/var/mobile/Library/Application Support/Inky/ColourMap.plist");

        self.defaultsKey = key;
        self.defaultsDomain = defaultsDomain;

        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:defaultsDomain];
        if(![defaults objectForKey:key]) {
            //There is no saved colour. If we have a default colour, set that, but if not, use [UIColor blackColor] instead.
            [defaults setObject:defaultColor ? @(colorToUInt(defaultColor)) : 0 forKey:key];

            //Do this here rather than doing it before and converting to hex - we already know the hex value for black.
            self.chosenColor = defaultColor ? defaultColor : [UIColor blackColor];
        } else {
            self.chosenColor = uintToColor([[defaults objectForKey:key] unsignedIntegerValue]);
        }
    }

    return self;
}

-(void)loadView {
    [super loadView];

    self.redSlider = [[UISlider alloc] initWithFrame:self.view.frame];
    self.greenSlider = [[UISlider alloc] initWithFrame:self.view.frame];
    self.blueSlider = [[UISlider alloc] initWithFrame:self.view.frame];

    self.redSlider.value = self.greenSlider.value = self.blueSlider.value = 0.0f;
    self.redSlider.minimumValue = self.greenSlider.minimumValue = self.blueSlider.minimumValue = 0.0f;
    self.redSlider.maximumValue = self.greenSlider.maximumValue = self.blueSlider.maximumValue = 255.0f;

    if(self.usesAlphaSlider) {
        self.alphaSlider = [[UISlider alloc] initWithFrame:self.view.frame];

        self.alphaSlider.value = 100.0;
        self.alphaSlider.minimumValue = 0.0;
        self.alphaSlider.maximumValue = 100.0;
    }

    //The frame positions are very rough; positioning is done through the center property instead. The frame sizes are correct.

    self.hexTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 319.0, self.view.frame.size.width, 30.0)];
    self.hexTextField.minimumFontSize = 13.0;
    self.hexTextField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBlack];
    self.hexTextField.textAlignment = NSTextAlignmentCenter;
    self.hexTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.hexTextField.backgroundColor = [UIColor clearColor];
    self.hexTextField.borderStyle = UITextBorderStyleNone;
    self.hexTextField.delegate = self;

    self.colorNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 268.0, 375.0, 42.0)];
    self.colorNameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBlack];
    self.colorNameLabel.textAlignment = NSTextAlignmentCenter;
    self.colorNameLabel.userInteractionEnabled = NO;
    self.colorNameLabel.textColor = [UIColor blueColor];

    self.previousColorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 264.0, 0.3 * self.view.frame.size.width, 50)];
    self.previousColorLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.previousColorLabel.textAlignment = NSTextAlignmentCenter;
    self.previousColorLabel.text = @"Previous";
    self.previousColorLabel.layer.cornerRadius = 9.0;
    self.previousColorLabel.adjustsFontSizeToFitWidth = YES;
    self.previousColorLabel.backgroundColor = self.chosenColor;
    self.previousColorLabel.clipsToBounds = YES;
    //Keep it hidden until we actually have a difference in colours to show.
    self.previousColorLabel.alpha = 0.0f;

    self.rgbLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 490.0, 375.0, 42.0)];
    self.rgbLabel.font = self.colorNameLabel.font;
    self.rgbLabel.textAlignment = NSTextAlignmentCenter;
    self.rgbLabel.userInteractionEnabled = NO;
    self.rgbLabel.textColor = foregroundColorForBackground(self.chosenColor);

    //This background view shows the current colour. self.view.backgroundColor is the grey checkered pattern.
    self.backgroundView = [[UIView alloc] initWithFrame:[[self view] frame]];
    self.backgroundView.backgroundColor = [UIColor blackColor];

    //Load the tick image used for the 'Done' button. It's actually a 3D Touch shortcut icon.
    NSBundle *sbuiFramework = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardUI.framework"];
    UIImage *tickImage;
    if(sbuiFramework) {
        tickImage = [UIImage imageNamed:@"SBSApplicationShortcutSystemIcon_Confirmation" inBundle:sbuiFramework compatibleWithTraitCollection:nil];
    }

    //Fallback for if we don't get the image.
    if(!tickImage) {
        //TODO: Replace with a UILabel subview that says 'Done'.
        tickImage = getImageFromColor([UIColor blackColor], CGSizeMake(40, 40));
    }

    //Rendering the image with UIImageRenderingModeAlwaysTemplate allows us to colour it using the image view's tint colour.
    tickImage = [tickImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.completeButton = [[UIImageView alloc] initWithImage:tickImage];
    self.completeButton.tintColor = [UIColor whiteColor];
    self.completeButton.frame = CGRectMake(0, 0, 40, 40);
}

-(BOOL)shouldAutorotate {
    //We don't want to have to worry about adjusting for different orientations.
    //Besides, who needs a landscape colour picker anyway?
    return NO;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

-(void)verticallyAlignBlock:(NSArray *)centerBlock fromTop:(UIView *)topView toBottom:(UIView *)bottomView animated:(BOOL)animated {
    CGPoint topCenter = topView.center;
    CGPoint bottomCenter = bottomView.center;

    CGRect screenRect = self.view.frame;

    //Get the height of the block of views we are going to centre.
    //This is the distance between topCenter and bottomCenter.
    CGFloat blockHeight = hypot((topCenter.x - bottomCenter.x), (topCenter.y - bottomCenter.y));

    //Work out where topCenter would be if the block was centred.
    CGFloat centeredTopY = (screenRect.size.height - blockHeight) / 2;

    //Get the value by which the Y value of all views in the block should be offset in order to centre the block.
    CGFloat blockYOffset = centeredTopY - topCenter.y;

    //Apply the offset to all applicable views.
    if(animated) {
        [UIView animateWithDuration:0.2 animations:^{
            for(UIView *blockView in centerBlock) {
                CGPoint currentCenter = blockView.center;
                currentCenter.y += blockYOffset;

                blockView.center = currentCenter;
            }
        }];
    } else {
        for(UIView *blockView in centerBlock) {
            CGPoint currentCenter = blockView.center;
            currentCenter.y += blockYOffset;

            blockView.center = currentCenter;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _updateCount = 0;

    //Since self.completeButton is actually a UIImageView, we need to implement a gesture recogniser.
    self.completeButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *completeButtonTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(excuseSelf)];
    [self.completeButton addGestureRecognizer:completeButtonTap];

    UILongPressGestureRecognizer *resetGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [resetGestureRecognizer addTarget:self action:@selector(resetToPreviousColour:)];
    [self.previousColorLabel addGestureRecognizer:resetGestureRecognizer];
    self.previousColorLabel.userInteractionEnabled = YES;

    //We need to be able to update the colour as soon as we get a valid hex string.
    [self.hexTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    //The sliders should be 2/3 the width of the screen so that it doesn't feel too cramped, but there is plenty of space for fine-tuning.
    CGRect sliderFrame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, self.view.frame.size.width * 0.67, 31);
    self.redSlider.frame = self.greenSlider.frame = self.blueSlider.frame = sliderFrame;

    if(self.usesAlphaSlider) self.alphaSlider.frame = sliderFrame;

    //We set up the basic positions here, but everything will be vertically aligned later.
    self.backgroundView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);

    self.colorNameLabel.frame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - 40, self.view.frame.size.width, 42);
    self.hexTextField.frame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, self.view.frame.size.width, 30);

    self.colorNameLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - self.colorNameLabel.frame.size.height - 80);
    self.hexTextField.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - 80);

    self.redSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 50 - 80);
    self.greenSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 100 - 80);
    self.blueSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 150 - 80);

    //Without the alpha slider, the offset for the next elements should be 200. With it, it should be 250.
    CGFloat yOffset = 200.0f;
    if(self.usesAlphaSlider) {
        self.alphaSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 200 - 80);

        yOffset += 50;
    }

    self.rgbLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + yOffset - 80);

    if(self.usesColorComparison) {
        self.previousColorLabel.center = CGPointMake(self.view.frame.size.width / 2, self.rgbLabel.center.y + 70);
    }

    self.completeButton.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + yOffset + 130 - 80);

    //We want to update the colour every time a slider's value changes.
    [self.redSlider addTarget:self action:@selector(sliderValueChanged:event:) forControlEvents:UIControlEventValueChanged];
    [self.greenSlider addTarget:self action:@selector(sliderValueChanged:event:) forControlEvents:UIControlEventValueChanged];
    [self.blueSlider addTarget:self action:@selector(sliderValueChanged:event:) forControlEvents:UIControlEventValueChanged];
    if(self.usesAlphaSlider) [self.alphaSlider addTarget:self action:@selector(sliderValueChanged:event:) forControlEvents:UIControlEventValueChanged];

    //Set views to be opaque (for performance).
    self.redSlider.opaque = YES;
    self.greenSlider.opaque = YES;
    self.blueSlider.opaque = YES;
    self.hexTextField.opaque = YES;
    self.colorNameLabel.opaque = YES;
    self.rgbLabel.opaque = YES;
    self.completeButton.opaque = YES;
    if(self.usesAlphaSlider) self.alphaSlider.opaque = YES;

    UIView *topView = self.colorNameLabel;
    UIView *bottomView = self.rgbLabel;

    NSMutableArray *centerBlock = [@[self.colorNameLabel, self.hexTextField, self.redSlider, self.greenSlider, self.blueSlider, self.rgbLabel, self.completeButton] mutableCopy];
    if(self.usesAlphaSlider) {
        [centerBlock addObject:self.alphaSlider];
    }

    [self verticallyAlignBlock:centerBlock fromTop:topView toBottom:bottomView animated:NO];

    //Load the transparency image for display in the backgroundColor.
    NSData *imageData = [NSData dataWithBytes:transparency length:transparencyLength];
    UIColor *transparencyColor = [UIColor colorWithPatternImage:[UIImage imageWithData:imageData]];
    self.view.backgroundColor = transparencyColor;

    //Add all the subviews.
    //We created them and nurtured them into adulthood, and now they're ready to leave and fend for themselves in the big outside UIView.
    // *cries*
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.redSlider];
    [self.view addSubview:self.greenSlider];
    [self.view addSubview:self.blueSlider];
    [self.view addSubview:self.hexTextField];
    [self.view addSubview:self.colorNameLabel];
    [self.view addSubview:self.rgbLabel];
    [self.view addSubview:self.completeButton];
    //And the ugly duckling of the lot:
    if(self.usesAlphaSlider) [self.view addSubview:self.alphaSlider];
    //And the forgotten one:
    if(self.usesColorComparison) [self.view addSubview:self.previousColorLabel];

    //EclipseGuard®
    //DOESN'T BLOODY WORK BECAUSE BLACK COLOURS ARE CHANGED TO SOME SHITTY GREY
    self.backgroundView.tag = 199;
    self.view.tag = 199;
    self.hexTextField.tag = 199;
    self.colorNameLabel.tag = 199;
    self.completeButton.tag = 199;
    self.rgbLabel.tag = 199;

    //Show the first colour.
    [self updateWithColor:self.chosenColor];

    for(UIView *subview in [self.view subviews]) {
        [subview setTag:199];
        [subview.subviews makeObjectsPerformSelector:@selector(setTag:) withObject:@199];
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    //Why not?
    return YES;
}

-(void)sliderValueChanged:(UISlider *)slidey event:(UIEvent *)event {
    UIColor *newColor = [UIColor colorWithRed:self.redSlider.value / 255.0
                                        green:self.greenSlider.value / 255.0
                                         blue:self.blueSlider.value / 255.0
                                        alpha:self.usesAlphaSlider ? self.alphaSlider.value / 100 : 1.0f];

    if(self.usesColorComparison && self.previousColorLabel.alpha == 0.0f && [[[event allTouches] anyObject] phase] == UITouchPhaseEnded) {
        [self updateForPreviousColorLabel];
    }

    [self updateWithColor:newColor];
}

-(void)textFieldDidChange:(UITextField *)tf {
    NSCharacterSet *illegalCharacters = [NSCharacterSet characterSetWithCharactersInString:@"#0123456789ABCDEF"].invertedSet;
    if(tf.text.length < 7 || [[tf.text uppercaseString] rangeOfCharacterFromSet:illegalCharacters].location != NSNotFound) return;

    [self updateWithColor:colorFromString([tf.text uppercaseString])];
}

-(void)updateForPreviousColorLabel {
    UIView *topView = self.colorNameLabel;
    UIView *bottomView = self.previousColorLabel;

    NSMutableArray *block = [@[self.colorNameLabel, self.hexTextField, self.redSlider, self.greenSlider, self.blueSlider, self.rgbLabel, self.previousColorLabel, self.completeButton] mutableCopy];
    if(self.usesAlphaSlider) {
        [block addObject:self.alphaSlider];
    }

    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionReveal];
    [animation setSubtype:kCATransitionFromTop];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

    [self verticallyAlignBlock:block fromTop:topView toBottom:bottomView animated:YES];
    self.completeButton.alpha = 0.0f;
    CGPoint completeButtonCenter = self.completeButton.center;
    completeButtonCenter.y += 50;
    self.completeButton.center = completeButtonCenter;

    [UIView animateWithDuration:0.2 animations:^{
        self.previousColorLabel.alpha = 1.0f;
    }];

    [UIView animateWithDuration:0.2 animations:^{
        self.completeButton.alpha = 1.0f;
    }];
}

-(void)updateWithColor:(UIColor *)color {
    self.chosenColor = self.backgroundView.backgroundColor = color;

    const unsigned chosenInt = colorToUInt(self.chosenColor);
    const unsigned sliderInt = createUIntColor(self.redSlider.value / 255.0,
                                               self.greenSlider.value / 255.0,
                                               self.blueSlider.value / 255.0,
                                               self.usesAlphaSlider ? self.alphaSlider.value / 100 : 1.0f);

    //If the sliders don't show the actual colour value, this must be a hex string update. Update the slider values.
    if(chosenInt != sliderInt) {
        CGFloat red, green, blue, alpha;
        [self.chosenColor getRed:&red green:&green blue:&blue alpha:&alpha];

        [UIView animateWithDuration:0.2 animations:^{
            [self.redSlider setValue:red * 255.0 animated:YES];
            [self.greenSlider setValue:green * 255.0 animated:YES];
            [self.blueSlider setValue:blue * 255.0 animated:YES];
            if(self.usesAlphaSlider) [self.alphaSlider setValue:alpha * 100.0 animated:YES];
        }];
    }

    //All string stuff is done async because, well, STRING stuff.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *name = getColorName(self.chosenColor, _colorNames);
        NSString *hex = stringFromColor(self.chosenColor);
        NSString *rgbText = [NSString stringWithFormat:@"R: %.0f   G: %.0f   B: %.0f", self.redSlider.value, self.greenSlider.value, self.blueSlider.value];

        if(self.usesAlphaSlider) {
            rgbText = [NSString stringWithFormat:@"R: %.0f   G: %.0f   B: %.0f   A: %.2f", self.redSlider.value, self.greenSlider.value, self.blueSlider.value, self.alphaSlider.value / 100];
        }

        //Switch back to the main thread for UI updates.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.colorNameLabel.text = name;
            [self.hexTextField setText:hex];
            self.rgbLabel.text = rgbText;
        });
    });

    if(self.usesColorComparison) self.previousColorLabel.textColor = foregroundColorForBackground(self.previousColorLabel.backgroundColor);

    //Get the colour that the UI should be.
    UIColor *foregroundColor = foregroundColorForBackground(self.chosenColor);

    //Check if we need to update. Updating without checking causes a new kind of lag, know to scientists as UltraLag.
    if(![self.colorNameLabel.textColor isEqual:foregroundColor]) {
        //Get an animation going for the elements we are able to animate.
        static CATransition *transitionAnimation;

        //Only set up if we haven't already done so.
        if(!transitionAnimation) {
            transitionAnimation = [CATransition animation];
            [transitionAnimation setType:kCATransitionFade];
            [transitionAnimation setDuration:0.05f];
            [transitionAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [transitionAnimation setFillMode:kCAFillModeBoth];
        }

        //Add the animation to what we can. The sliders look good but the thumb movement gets animated and looks terrible.
        [self.colorNameLabel.layer addAnimation:transitionAnimation forKey:@"fadeUpdate"];
        [self.completeButton.layer addAnimation:transitionAnimation forKey:@"fadeUpdate"];
        [self.hexTextField.layer addAnimation:transitionAnimation forKey:@"fadeUpdate"];
        [self.rgbLabel.layer addAnimation:transitionAnimation forKey:@"fadeUpdate"];

        [self.colorNameLabel setTextColor:foregroundColor];
        [((_UILabelLayer *)self.colorNameLabel.layer) setContentsMultiplyColor:foregroundColor.CGColor];
        self.doneButton.layer.backgroundColor = foregroundColor.CGColor;

        self.redSlider.minimumTrackTintColor = foregroundColor;
        self.greenSlider.minimumTrackTintColor = foregroundColor;
        self.blueSlider.minimumTrackTintColor = foregroundColor;

        self.hexTextField.textColor = foregroundColor;

        self.redSlider.maximumTrackTintColor = foregroundColor;
        self.greenSlider.maximumTrackTintColor = foregroundColor;
        self.blueSlider.maximumTrackTintColor = foregroundColor;
        if(self.usesAlphaSlider) {
            self.alphaSlider.minimumTrackTintColor = foregroundColor;
            self.alphaSlider.maximumTrackTintColor = foregroundColor;
        }

        self.rgbLabel.textColor = foregroundColor;
        self.completeButton.tintColor = foregroundColor;

        [[UIApplication sharedApplication] setValue:foregroundColor forKeyPath:@"_statusBar.foregroundColor"];

        self.redSlider.thumbTintColor = foregroundColor;
        self.greenSlider.thumbTintColor = foregroundColor;
        self.blueSlider.thumbTintColor = foregroundColor;
        if(self.usesAlphaSlider) {
            self.alphaSlider.thumbTintColor = foregroundColor;
        }

        //Set the tint colour of the hex text field - this changes the caret colour.
        [self.hexTextField setTintColor:foregroundColor];
    }

    _updateCount++;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //Get the string after the change.
    NSString *proposedNewString = [[textField.text stringByReplacingCharactersInRange:range withString:string] uppercaseString];

    //Make sure the characters are only hexadecimal characters and '#'.
    NSRange illegalCharRange = [proposedNewString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"#0123456789ABCDEF"].invertedSet];

    //Check if there are any characters that are in the invalid set.
    if(illegalCharRange.location != NSNotFound) {
        return NO;
    }

    //Count the occurrences of '#' in the string. This should be 1.
    const unsigned hashCount = [[proposedNewString componentsSeparatedByString:@"#"] count] - 1;
    if(hashCount != 1) return NO;

    //Check the length. This should be 7 to allow for a hex string and also a hash at the start.
    if([proposedNewString length] > 7) {
        return NO;
    }

    //We never actually return YES. Instead, we make the changes here so we have control over the string case.
    textField.text = proposedNewString;

    //We need to trigger the UI update manually.
    [self textFieldDidChange:textField];
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //Get rid of the keyboard on pressing the return key.
    [textField resignFirstResponder];
    return YES;
}

-(void)resetToPreviousColour:(UILongPressGestureRecognizer *)rec {
    static bool hasAskedForUpdate = false;
    if(rec.state == UIGestureRecognizerStateChanged && !hasAskedForUpdate) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset Colour" message:@"Do you want to reset to the previous colour?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *reset = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIColor *previousColor = [self.previousColorLabel backgroundColor];
            [self.previousColorLabel setBackgroundColor:self.chosenColor];
            self.chosenColor = previousColor;
            [self updateWithColor:previousColor];
        }];

        [alert addAction:reset];

		UIAlertAction *nahForgetIt = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		[alert addAction:nahForgetIt];
	    [self presentViewController:alert animated:YES completion:nil];

        hasAskedForUpdate = true;
    } else if(rec.state != UIGestureRecognizerStateChanged) {
        hasAskedForUpdate = false;
    }
}

-(void)excuseSelf {
    if([self.defaultsDomain isKindOfClass:[NSString class]]) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:self.defaultsDomain];
        [defaults setObject:@(colorToUInt(self.chosenColor)) forKey:self.defaultsKey];
        [defaults synchronize];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"There was an error saving the colour. Would you like to copy the hex code to your pasteboard?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *copy = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIPasteboard generalPasteboard] setString:[self.hexTextField.text substringFromIndex:1]];
        }];

        [alert addAction:copy];

		UIAlertAction *nahForgetIt = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		[alert addAction:nahForgetIt];
	    [self presentViewController:alert animated:YES completion:nil];
    }

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    [[UIApplication sharedApplication] setValue:self.originalStatusBarColor forKeyPath:@"_statusBar.foregroundColor"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SQColorPickerViewControllerDidExit" object:self];
}

@end
