export DEVELOPER_DIR := $(shell xcode-select --print-path)
SDK_IOS := $(shell xcodebuild -version -sdk iphoneos Path)

MIN_VER_IOS=-miphoneos-version-min=7.0
ARCH_IOS=-arch armv7 -arch arm64
CC_IOS=xcrun -sdk "iphoneos" clang

all: main.m
	$(CC_IOS) -o xpcd_cache_util main.m $(ARCH_IOS) $(MIN_VER_IOS) -isysroot $(SDK_IOS) -I$(SDK_IOS)/usr/include -framework Foundation
	ldid -S xpcd_cache_util

clean:
	rm -f xpcd_cache_util
