#pragma once
#include <stdbool.h>
void sendMessageJNI(int typ, int obj);
void showMessageDialogJNI(const char* message);
void writeDebugJNI(const char* message);
void playMovieJNI(const char* address);
void drawFPSJNI(int fps);
void setFPSVisibilityJNI(bool isVisible);