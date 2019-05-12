ARCHS = arm64 arm64e
TARGET = iphone:clang:11.2:11.2
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Relocate
$(TWEAK_NAME)_FILES = Tweak.xm RLCAnalogStickWindow.m
ADDITIONAL_OBJCFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = CoreLocation QuartzCore
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk