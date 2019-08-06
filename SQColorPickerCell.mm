#include "SQColorPickerCell.h"

@implementation SQColorPickerCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)rID specifier:(PSSpecifier *)specifier {
    [specifier setTarget:self];
    [specifier setButtonAction:@selector(showPicker)];

    if(self = [super initWithStyle:style reuseIdentifier:rID specifier:specifier]) {
        self.defaultsDomain = [specifier properties][@"defaultsDomain"];
        if(!self.defaultsDomain) {
            [NSException raise:@"self.defaultsDomain is nil!" format:@"self.defaultsDomain should be NSString, actually %@", self.defaultsDomain];
        }

        self.defaultsKey = [specifier properties][@"defaultsKey"];
        if(!self.defaultsKey) {
            [NSException raise:@"self.defaultsKey is nil!" format:@"self.defaultsDomain should be NSString, actually %@", self.defaultsKey];
        }

        self.defaultColor = uintToColor([[specifier properties][@"defaultColor"] unsignedIntValue]);
        if(!self.defaultColor) {
            self.defaultColor = [UIColor blackColor];
        }

        self.usesAlphaSlider = [specifier properties][@"usesAlphaSlider"] != nil;
        self.usesColorComparison = [specifier properties][@"usesColorComparison"] != nil;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSubviews) name:@"SQColorPickerViewControllerDidExit" object:nil];
    }

    return self;
}

-(void)updateTintColor {
    //The badge tint colour will be the colour we get from NSUserDefaults.
    if(![self.defaultsDomain isKindOfClass:[NSString class]] || ![self.defaultsKey isKindOfClass:[NSString class]]) return;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:self.defaultsDomain];
    unsigned color = [[defaults objectForKey:self.defaultsKey] unsignedIntValue];

    if(!color) {
        color = colorToUInt(self.defaultColor);
    }

    self.tintColor = uintToColor(color);
}

-(void)showPicker {
    //Create a colour picker that uses the defaults domain and key.
    SQColorPickerViewController *colorPicker = [[SQColorPickerViewController alloc] initWithDefaultsKey:self.defaultsKey domain:self.defaultsDomain defaultColor:self.defaultColor];
    colorPicker.usesAlphaSlider = self.usesAlphaSlider;
    colorPicker.usesColorComparison = self.usesColorComparison;

    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:colorPicker animated:YES completion:nil];
}

-(void)layoutSubviews {
    //Fetch the colour from NSUserDefaults and store it in self.tintColor.
    [self updateTintColor];
    [super layoutSubviews];

    //Hide the fact that this is a button cell by changing the title colour.
    self.textLabel.textColor = [UIColor blackColor];

    //Set up the badge if needed.
    if(!self.colorBadge) {
        //In order to make the cell feel more like part of iOS, we use the badge that can be seen on some cells
        //  in stock iOS (for example, on the General cell when an update is available).

        //PSBadgedTableCell has a class method that provides the base icon image we need. If this is rendered with
        //  the UIImageRenderingModeAlwaysTemplate mode, we can change its colour through UIImageView's tintColor.
        UIImage *templateBadgeImage = [[PSBadgedTableCell unreadBubbleImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

        //Set up the image view.
        self.colorBadge = [[UIImageView alloc] initWithImage:templateBadgeImage];
        self.colorBadge.center = CGPointMake(self.frame.size.width * 64 / 75, self.frame.size.height / 2);//CGPointMake(320.0f, 22.0f);
        [self addSubview:self.colorBadge];
    }

    //Set the badge colour.
    self.colorBadge.tintColor = self.tintColor;

    if(!self.accessoryView) {
        //Grab a disclosure indicator off a fake cell.
        PSTableCell *fakeCell = [PSTableCell new];

        UIImage *chevron = [fakeCell performSelector:@selector(_disclosureChevronImage:) withObject:@YES];
        chevron = [chevron imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.accessoryView = [[UIImageView alloc] initWithImage:chevron];
        self.accessoryView.frame = CGRectMake(self.accessoryView.frame.origin.x, self.accessoryView.frame.origin.y, 8, 13);
    }

    self.accessoryView.tintColor = self.tintColor;
}

@end
