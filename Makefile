export ARCHS = armv7
export TARGET = iphone:clang:10.3:8.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MusicClone

MusicClone_FILES = main.m MCCore.m MCViews.m
MusicClone_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore AVFoundation MediaPlayer CoreMedia
MusicClone_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unguarded-availability

include $(THEOS_MAKE_PATH)/application.mk
