THEOS_DEVICE_IP = 192.168.1.139

include /home/squid/theos/makefiles/common.mk

LIBRARY_NAME = libinky

libinky_FILES = Inky.mm SQColorPickerViewController.mm SQColorPickerCell.mm
libinky_CFLAGS = -fobjc-arc
libinky_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/library.mk
