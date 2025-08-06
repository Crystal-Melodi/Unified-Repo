APP_ABI := armeabi-v7a arm64-v8a #x86_64
APP_PLATFORM := android-21
APP_OPTIM := release
APP_STL := c++_shared
APP_CPPFLAGS := -std=c++11 -frtti -fexceptions -O1 -ffunction-sections -fdata-sections
APP_CFLAGS := -O1 -ffunction-sections -fdata-sections

ifeq ($(TARGET_ARCH_ABI), armeabi-v7a)
	APP_CPPFLAGS += -DARCH_32BIT -DABI_ARMEABI_V7A -march=armv7-a -mfpu=neon -mfloat-abi=softfp
else ifeq ($(TARGET_ARCH_ABI), arm64-v8a)
	APP_CPPFLAGS += -DARCH_64BIT -DABI_ARM64_V8A -march=armv8-a
endif
