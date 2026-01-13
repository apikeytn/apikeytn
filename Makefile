TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libAPIKeyThNhan
libAPIKeyThNhan_FILES = Tweak.x
libAPIKeyThNhan_CFLAGS = -fobjc-arc
libKeySystem_FRAMEWORKS = UIKit Foundation QuartzCore

include $(THEOS_MAKE_PATH)/library.mk

