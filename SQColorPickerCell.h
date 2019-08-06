#include <Preferences/PSTableCell.h>
#include <Preferences/PSBadgedTableCell.h>
#include <Preferences/PSSpecifier.h>
#include "SQColorPickerViewController.h"

@interface SQColorPickerCell : PSTableCell
@property (nonatomic, assign, readwrite) NSString *defaultsKey;
@property (nonatomic, assign, readwrite) NSString *defaultsDomain;
@property (nonatomic, copy) UIColor *defaultColor;
@property (nonatomic, copy) UIColor *currentColor;
@property (nonatomic, strong) UIImageView *colorBadge;
@property (nonatomic, assign, readwrite) BOOL usesAlphaSlider;
@property (nonatomic, assign, readwrite) BOOL usesColorComparison;
@end
