THEOS_DEVICE_IP = 192.168.1.139

include /home/squid/theos/makefiles/common.mk

LIBRARY_NAME = Inky

Inky_FILES = Inky.mm SQColorPickerViewController.mm SQColorPickerCell.mm
Inky_CFLAGS = -fobjc-arc
Inky_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/library.mk
