package org.ancurio.mkxp;

import android.content.Context;

import java.io.File;

public class MKXP
{
    public static String getLibDir(Context c) {
        String s = c.getApplicationInfo().nativeLibraryDir;
        if (!s.endsWith(File.separator)) {
            s += File.separator;
        }
        return s;
    }
    public static native void loadLibs(String path);
    public static native void unloadLibs();
}
