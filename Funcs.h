#import <UIKit/UIKit.h>
@import QuartzCore;

inline unsigned char hexDigitsToChar(NSString *hexDigits) {
    static NSString *digits = @"0123456789ABCDEF";

    const char sixteens = [digits rangeOfString:[NSString stringWithFormat:@"%c", [hexDigits characterAtIndex:0]]].location;

    const char units = [digits rangeOfString:[NSString stringWithFormat:@"%c", [hexDigits characterAtIndex:1]]].location;

    u_char result = sixteens * 16 + units;

    return result;
}

inline UIColor *colorFromString(NSString *hexStr) {
    hexStr = [hexStr stringByReplacingOccurrencesOfString:@"#" withString:@""];

    unsigned char allValues[3];

    char *digitPairs[3];
    for(int i = 0, iters = 0; i < 6; i += 2, iters++) {
        //NSLog(@"i = %d, iters = %d", i, iters);
        char thisPair[2] = { static_cast<char>([hexStr characterAtIndex:i]), static_cast<char>([hexStr characterAtIndex:i + 1]) };
        digitPairs[iters] = thisPair;
        allValues[iters] = hexDigitsToChar([NSString stringWithFormat:@"%s", thisPair]);
    }

    const CGFloat red = allValues[0];
    const CGFloat green = allValues[1];
    const CGFloat blue = allValues[2];

    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0f];
}

inline NSString *stringFromColor(UIColor *color) {
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

inline NSString *stringFromColor2(UIColor *color) {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(red * 255),
            lroundf(green * 255),
            lroundf(blue * 255)];
}

inline UIColor *complementaryColor(UIColor *col) {
    CGFloat hue, saturation, brightness, alpha;
    [col getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    //Get the opposite hue.
    CGFloat oppositeHue = 1.0f - hue;
    return [UIColor colorWithHue:oppositeHue saturation:saturation brightness:brightness alpha:alpha];
}

inline UIColor *foregroundColorForBackground(UIColor *background) {
    CGFloat red, green, blue, alpha;
    [background getRed:&red green:&green blue:&blue alpha:&alpha];

    if(alpha <= 0.4) return [UIColor blackColor];

    return (((red * 255 * 0.299) + (green * 255 * 0.587) + (blue * 255 * 0.114)) > 186) ? [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0f] : [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
}

@interface NSKeyedUnarchiver (TheosWontWorkHelp)
+(id)unarchivedObjectOfClass:(id)sth fromData:(id)ssth error:(id)sssth;
@end

inline NSDictionary *loadColorNames(NSString *file) {
    //The names and colours in the .plist are swapped around, because the colours (which should be the keys) are represented as NSData objects, whereas the names are NSStrings. Since a plist can't have NSData keys, they are swapped over.

    NSDictionary *loaded = [NSDictionary dictionaryWithContentsOfFile:file];

    NSMutableDictionary *swappedAndConverted = [NSMutableDictionary new];
    [loaded enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if([NSKeyedUnarchiver respondsToSelector:@selector(unarchivedObjectOfClass:fromData:error:)]) {
            swappedAndConverted[[NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:value error:nil]] = key;
        } else {
            swappedAndConverted[[NSKeyedUnarchiver unarchiveObjectWithData:value]] = key;
        }
    }];

    NSLog(@"%@", swappedAndConverted);

    return [swappedAndConverted copy];
}

inline UIColor *closestColor(UIColor *toColor, NSArray *fromColors) {
    UIColor *closestFound = nil;
    float closestDifference = CGFLOAT_MAX;

    //Get toColor's RGBA components.
    CGFloat r, g, b, a;
    [toColor getRed:&r green:&g blue:&b alpha:&a];

    for(UIColor *color in fromColors) {
        //Get the RGBA components.
        CGFloat red, green, blue, alpha;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];

        //Get the average difference across R, G & B.
        const float thisDifference = (fabs(r - red) +
                                      fabs(g - green) +
                                      fabs(b - blue)) / 3.0f;

        if(thisDifference < closestDifference) {
            closestFound = color;
            closestDifference = thisDifference;
        }
    }

    return closestFound;
}

inline NSString *getColorName(UIColor *color, NSDictionary *colorsAndNames) {
    //Get the closest key from the dict.
    UIColor *closestKey = closestColor(color, [colorsAndNames allKeys]);

    return colorsAndNames[closestKey];
}

inline UIImage *getImageFromColor(UIColor *color, CGSize imageSize) {
    CGRect rect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

inline UIColor *dimColor(UIColor *original) {
    CGFloat red, green, blue, alpha;
    [original getRed:&red green:&green blue:&blue alpha:&alpha];

    return [UIColor colorWithRed:red * 0.76 green:green * 0.76 blue:blue * 0.76 alpha:alpha];
}

inline void showAlert(NSString *title, NSString *content, NSString *dismissButtonStr) {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:dismissButtonStr style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:dismiss];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
}

inline unsigned colorToUInt(UIColor *color) {
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];

    return ((unsigned)(r * 255) << 24) + ((unsigned)(g * 255) << 16) + ((unsigned)(b * 255) << 8) + ((unsigned)(a * 100) << 0);
}

inline unsigned createUIntColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return colorToUInt([UIColor colorWithRed:r green:g blue:b alpha:a]);
}

inline UIColor *uintToColor(unsigned colorInt) {
    unsigned r = colorInt >> 24 & 0xFF,
             g = colorInt >> 16 & 0xFF,
             b = colorInt >> 8  & 0xFF,
             a = colorInt >> 0  & 0xFF;

    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 100.0f];
}
