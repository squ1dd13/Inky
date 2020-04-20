# Inky
A beautiful, simple colour picker designed for iOS 11 and 12. (Tested on iOS 9, 10, 11 and 12.) Inky is primarily for preference bundles for jailbreak tweaks, but can be used anywhere in iOS.

## Features
- Full customisation of the colour picker through a .plist or through code
  - Optional alpha slider
  - Option to show previous colour for comparison
  - Customisable default colours
- A simple and responsive, yet fully functional, user interface that adheres to Apple's Human Interface Guidelines
- A colour naming system to help remember your favourite colours
- A hex input field that allows the user to use colours from other places
- A saving system that uses the Foundation framework's `NSUserDefaults` class for saving and loading
- PSTableCells that use iOS' stock badge style

## How do I use it?
1. Grab a [copy of the .dylib](/libinky.dylib) and copy it to your `$THEOS/lib` folder.
2. Add `inky` to `YourProject_LIBRARIES` in the Makefile for the project where you want to use Inky (if you want to use this in a preference bundle, this will be your prefs subproject folder).
3. Follow the correct steps for how you want to use it below.

### Using Inky in a preference bundle
1. Add an `SQColorPickerCell` entry to your preference bundle:
```xml
<dict>
  <key>cell</key>
  <string>PSButtonCell</string>
  <key>cellClass</key>
  <string>SQColorPickerCell</string>
  <key>defaultColor</key>
  <integer>10076672100</integer>
  <key>defaultsDomain</key>
  <string>com.you.yourproject</string>
  <key>defaultsKey</key>
  <string>yourColourKey</string>
  <key>label</key>
  <string>Choose a colour</string>
</dict>
```
2. Change the `defaultColor` value to what you want as a default colour (this is a word-order RGBA integer - read about it [here](https://en.wikipedia.org/wiki/RGBA_color_space#RGBA_hexadecimal_(word-order))). Any hex string can be converted to this format, simply by converting the string to a number (which you can do [here](https://www.rapidtables.com/convert/number/hex-to-decimal.html)) **with the alpha added onto the end**. For example, `FF0000` would become `FF0000FF`, and then `4278190335`. The alpha is on a scale of 0-255.
3. Change the `defaultsDomain` to something unique - something like your tweak's bundle ID - and the `defaultsKey` to something unique for your tweak.
4. Customise the cell values - this is where you can change what you want the colour picker to be like.
  - If you want an alpha slider, add `<key>usesAlphaSlider</key>` to the `dict` for the cell, and put absolutely anything as the value. Inky only checks if the key exists, not what the value is.
  - If you want the user to be able to see the old colour when they change the colour, add `<key>usesColorComparison</key>` with any value.
  
### Using Inky without a preference bundle
1. Interface `SQColorPickerViewController` (sorry there's no .h yet)
```objc
@interface SQColorPickerViewController : UIViewController
@property (nonatomic, copy) UIColor *chosenColor;
@property (nonatomic, assign, readwrite) NSString *defaultsKey;
@property (nonatomic, assign, readwrite) NSString *defaultsDomain;
@property (nonatomic, assign, readwrite) BOOL usesAlphaSlider;
@property (nonatomic, assign, readwrite) BOOL usesColorComparison;
-(id)initWithDefaultsKey:(NSString *)key domain:(NSString *)defaultsDomain defaultColor:(UIColor *)defaultColor;
@end
```
2. Set up and present the colour picker
```objc
//Create the colour picker with a defaults key, domain and colour. The defaultColor argument can be left as nil, but will then default to [UIColor blackColor].
SQColorPickerViewController *colorPicker = [[SQColorPickerViewController alloc] initWithDefaultsKey:@"favouriteColor" domain:@"com.you.yourdomain" defaultColor:[UIColor redColor]];

//Optional: Choose to use an alpha slider and/or colour comparison (showing the user the previous colour).
colorPicker.usesAlphaSlider = YES;
colorPicker.usesColorComparison = YES;

//Present the colour picker. The view controller you use is up to you, but here, the main view controller is used.
[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:colorPicker animated:YES completion:nil];
```

## How do I get the colours?
Something like this:
```objc
inline UIColor *colorFromDefaults(NSString *key, NSString *domain, UIColor *defaultColor) {
  NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:domain];
  NSNumber *colorValue = [defaults objectForKey:key];
  
  //If the colour wasn't found, return the default colour.
  if(!colorValue) return defaultColor;
  
  const unsigned colorInt = [colorValue intValue];
  
  //Get the different colour components.
  const unsigned r = colorInt >> 24 & 0xFF,
                 g = colorInt >> 16 & 0xFF,
                 b = colorInt >> 8  & 0xFF,
                 a = colorInt >> 0  & 0xFF;
  
  return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 100.0f];
}
```

You can then use this in your tweak:
```logos
static UIColor *favouriteColor;

#pragma mark Tweak stuff
...
#pragma mark End tweak stuff

%ctor {
  favouriteColor = colorFromDefaults(@"favouriteColor", @"com.you.yourdomain", [UIColor orangeColor]);
}
```

## What does it look like?
This:

![Apple](/green_apple_normal.png)![Alpha Slider](/alpha_down.png)![Prefs](/pref_bundle.png)
