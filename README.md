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
1. Grab a copy of the .dylib and copy it to your `$THEOS/lib` folder.
2. Add `inky` to `YourProject_LIBRARIES` in the Makefile for the project where you want to use Inky (if you want to use this in a preference bundle, this will be your prefs subproject folder).
3. Follow the correct steps for how you want to use it below.

### Using Inky in a preference bundle
1. Add an `SQColorPickerCell` entry to your preference bundle:
```plist
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
4. 

![Apple](/green_apple_normal.png)![Alpha Slider](/alpha_down.png)![Prefs](/pref_bundle.png)
