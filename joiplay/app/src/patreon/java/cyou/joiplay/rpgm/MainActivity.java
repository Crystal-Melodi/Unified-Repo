package cyou.joiplay.rpgm;

import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

import org.json.JSONObject;
import org.libsdl.app.SDLActivity;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;

import cyou.joiplay.commons.dialog.ErrorDialog;
import cyou.joiplay.commons.file.FileUtils;
import cyou.joiplay.commons.model.Game;
import cyou.joiplay.commons.model.GamePad;
import cyou.joiplay.commons.model.MKXPConfiguration;
import cyou.joiplay.commons.parser.MKXPConfigurationParser;
import cyou.joiplay.commons.parser.GamePadParser;
import cyou.joiplay.commons.parser.GameParser;
import cyou.joiplay.joipad.JoiPad;

public class MainActivity extends SDLActivity {
    static private final String TAG = "mkxp";

    static public final String RTP_PATH = Environment.getExternalStorageDirectory().getAbsolutePath()+File.separator+"JoiPlay"+File.separator+"RTP";
    static public String confPath = "";
    public final String CONF_FILE_NAME = "mkxp.conf";
    static public String gameFolder = "";
    static public String internalFolder = "";
    public String RGA_PATH = "";
    public String rgssExt = "";

    static public Game game = new Game();
    static public MKXPConfiguration configuration = new MKXPConfiguration();
    static public GamePad gamePad = new GamePad();

    private String execFile = "Game";
    private String execName = "execName=Game";
    private ArrayList<String> preloadScripts = new ArrayList<>();
    private ArrayList<String> postloadScripts = new ArrayList<>();
    private String customScript = "";
    private String keyMapping = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFormat(PixelFormat.TRANSLUCENT);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R){
            getWindow().setDecorFitsSystemWindows(false);
            WindowInsetsController windowInsetsController = getWindow().getDecorView().getWindowInsetsController();
            windowInsetsController.hide(WindowInsets.Type.systemBars());
            windowInsetsController.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        } else {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY |
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
                    View.SYSTEM_UI_FLAG_FULLSCREEN |
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        }

        try {
            String gameJson = getIntent().getStringExtra("game");
            String settingsJson = getIntent().getStringExtra("settings");

            GameParser.parse(game, gameJson);
            MKXPConfigurationParser.parse(configuration, settingsJson);
            GamePadParser.parse(gamePad, settingsJson);

            loadConfig();

            if (getIntent().hasExtra("preloadScripts")){
                preloadScripts = getIntent().getStringArrayListExtra("preloadScripts");
            }

            if (getIntent().hasExtra("postloadScripts")){
                postloadScripts = getIntent().getStringArrayListExtra("postloadScripts");
            }

            if (getIntent().hasExtra("customScript")){
                customScript = getIntent().getStringExtra("customScript");
            }
        } catch (Exception e){
            Log.d(TAG, Log.getStackTraceString(e));
            showErrorDialog(e);
        }

        super.onCreate(savedInstanceState);

        gameFolder = game.folder;

        boolean inExternal = !(gameFolder.startsWith(Environment.getExternalStorageDirectory().getAbsolutePath()) || gameFolder.startsWith("/sdcard"));

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
            inExternal = false;

        if (inExternal){
            internalFolder = getExternalFilesDir(null).getAbsolutePath() + File.separator + game.id;
            File iFile = new File(internalFolder);
            try{
                if (!iFile.exists()) iFile.mkdirs();
                String iniFilePath = gameFolder + File.separator + "Game.ini";
                String targetPath = internalFolder + File.separator + "Game.ini";
                FileUtils.copy(iniFilePath, targetPath);
            } catch (Exception e){
                showErrorDialog(e);
            }
        } else {
            internalFolder = gameFolder;
        }

        RGA_PATH = game.folder;

        if (game.execFile.replaceAll("\\s+","").length() > 0){
            try {
                File iniFile = new File(internalFolder + File.separator + "Game.ini");
                String tmpExecFile = new File(game.execFile).getName();
                if (tmpExecFile.contains(".")){
                    execFile = tmpExecFile.substring(0, tmpExecFile.indexOf("."));
                } else {
                    execFile = tmpExecFile;
                }

                if (!iniFile.exists()) {
                    execName = "execName="+execFile;
                }
            } catch (Exception e){
                Log.d(TAG, Log.getStackTraceString(e));
            }
        } else {
            try{
                File iniFile = new File(internalFolder + File.separator + "Game.ini");
                if (!iniFile.exists()) {
                    File[] files = new File(internalFolder).listFiles();
                    String altIni = null;
                    if (files != null){
                        for (File file : files) {
                            if (file.getName().toLowerCase().endsWith(".ini"))
                                altIni = file.getName().substring(0, file.getName().indexOf("."));
                        }
                    }

                    if (altIni != null)
                        execName = "execName="+altIni;
                }
            } catch (Exception e){
                Log.d(TAG, Log.getStackTraceString(e));
            }
        }

        String rpgStr = "RPGXP";

        switch (game.type){
            case "rpgmxp":
                rpgStr = "RPGXP";
                rgssExt = "rgssad";
                break;
            case "rpgmvx":
                rpgStr = "RPGVX";
                rgssExt = "rgss2a";
                break;
            case "rpgmvxace":
                rpgStr = "RPGVXACE";
                rgssExt = "rgss3a";
                break;
            case "mkxp-z":
                rpgStr = "mkxp-z";
                rgssExt = "rgssad";
                break;
        }

        String forcedWidth = configuration.forcedDim.split("x")[0];
        String forcedHeight = configuration.forcedDim.split("x")[1];

        if (game.type.contentEquals("mkxp-z")){
            preloadScripts = new ArrayList<>();
            postloadScripts = new ArrayList<>();
        }

        if (customScript.length() > 0){
            customScript = "customScript="+customScript;
        }

        if (configuration.debug){
            mSingleton.isDebugEnabled = true;
            try {
                File logFile = new File(internalFolder+File.separator+"logs.txt");
                if (logFile.exists())
                    logFile.delete();
                logFile.createNewFile();
            } catch (Exception e){
                Log.d(TAG, Log.getStackTraceString(e));
            }
        }

        File preloadFile = new File(gameFolder+File.separator+"preload.rb");
        if (preloadFile.exists())
            preloadScripts.add("preload.rb");

        File postloadFile = new File(gameFolder+File.separator+"postload.rb");
        if (postloadFile.exists())
            postloadScripts.add("postload.rb");

        File keyMappingsFile = new File(Environment.getExternalStorageDirectory().getAbsolutePath()+File.separator+"joiplay_mappings.txt");
        if (keyMappingsFile.exists())
            keyMapping = "keyMapping="+keyMappingsFile.getAbsolutePath();

        confPath = getExternalFilesDir(null).getAbsolutePath()+File.separator+CONF_FILE_NAME;

        String rtpPath = RTP_PATH+File.separator+rpgStr+File.separator+"app";
        String sfPath = rtpPath+File.separator+"sf.sf2";

        if (configuration.customFont.length() > 0){
            try{
                File customFontSourceFile = new File(configuration.customFont);

                if (customFontSourceFile.exists()){
                    String customFontTarget = rtpPath+File.separator+customFontSourceFile.getName();
                    FileUtils.copy(customFontSourceFile.getAbsolutePath(), customFontTarget);
                    configuration.customFont = customFontSourceFile.getName();
                }
            } catch (Exception e){
                Log.d(TAG, Log.getStackTraceString(e));
            }
        }

        String patchString = "";
        File patchFolder = new File(gameFolder+File.separator+"patch");
        if (patchFolder.exists())
            patchString = "RTP="+patchFolder.getAbsolutePath();

        String rgssArchiveString = "";
        File exeArchive = new File(gameFolder+File.separator+execFile+"."+rgssExt);
        File defArchive = new File(gameFolder+File.separator+"Game."+rgssExt);
        if (exeArchive.exists()) {
            rgssArchiveString = "RTP="+exeArchive.getAbsolutePath();
        } else if (defArchive.exists()) {
            rgssArchiveString = "RTP="+defArchive.getAbsolutePath();
        }

        StringBuilder preloadStringBuilder = new StringBuilder();
        for (String preloadScript : preloadScripts){
            preloadStringBuilder.append("preloadScript=").append(preloadScript).append("\n");
        }

        StringBuilder postloadStringBuilder = new StringBuilder();
        for (String postloadScript : postloadScripts){
            postloadStringBuilder.append("postloadScript=").append(postloadScript).append("\n");
        }

        createUserDataFolders(internalFolder);

        try{
            File configFile = new File(confPath);
            if (configFile.exists()){
                configFile.delete();
            }
            configFile.createNewFile();
            configFile.deleteOnExit();

            FileOutputStream fos = new FileOutputStream(configFile);
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(getAssets().open(CONF_FILE_NAME)));

            while (true){
                String read = bufferedReader.readLine();
                if (read == null) {
                    break;
                }
                fos.write((read.replaceAll("PATCH_PATH", patchString)
                        .replaceAll("RGA_PATH", gameFolder)
                        .replaceAll("RTP_PATH",rtpPath)
                        .replaceAll("GAME_FOLDER", internalFolder)
                        .replaceAll("EXECNAME_VALUE", execName)
                        .replaceAll("RGSS_EXT", rgssArchiveString)
                        .replaceAll("PRELOAD_SCRIPTS", preloadStringBuilder.toString())
                        .replaceAll("POSTLOAD_SCRIPTS", postloadStringBuilder.toString())
                        .replaceAll("KEYMAPPING_VALUE", keyMapping)
                        .replaceAll("CUSTOMSCRIPT_VALUE", customScript)
                        .replaceAll("CUSTOMFONT_VALUE", configuration.customFont)
                        .replaceAll("CHEATS_VALUE", configuration.cheats ? "true" : "false")
                        .replaceAll("SMOOTHSCALING_VALUE", configuration.smoothScaling ? "true" : "false")
                        .replaceAll("VSYNC_VALUE", configuration.vsync ? "true" : "false")
                        .replaceAll("FRAMESKIP_VALUE", configuration.frameSkip ? "true" : "false")
                        .replaceAll("SPEEDUP_VALUE", configuration.fastForwardSpeed)
                        .replaceAll("SOLIDFONTS_VALUE",configuration.solidFonts ? "true" : "false")
                        .replaceAll("FONTSCALE_VALUE", configuration.fontScale)
                        .replaceAll("FORCEDWIDTH_VALUE", forcedWidth)
                        .replaceAll("FORCEDHEIGHT_VALUE", forcedHeight)
                        .replaceAll("PATHCACHE_VALUE", configuration.pathCache ? "true" : "false")
                        .replaceAll("PREBUILTCACHE_VALUE", configuration.prebuiltPathCache ? "true" : "false")
                        .replaceAll("ENABLEPOSTLOADSCRIPTS_VALUE", configuration.enablePostloadScripts ? "true" : "false")
                        .replaceAll("COPYTEXT_VALUE", configuration.copyText ? "true" : "false")
                        .replaceAll("SOUNDFONT_FILE", sfPath)
                        + "\n").getBytes());
            }
            fos.close();
            bufferedReader.close();
        } catch (Exception e){
            showErrorDialog(e);
        }

        JoiPad joiPad = new JoiPad();
        joiPad.init(this, gamePad);
        joiPad.cheats(configuration.cheats);
        joiPad.setGame(game);
        joiPad.setOnCloseListener(super::onDestroy);
        joiPad.setOnKeyDownListener(SDLActivity::onNativeKeyDown);
        joiPad.setOnKeyUpListener(SDLActivity::onNativeKeyUp);

        if (mLayout != null){
            super.joiPad = joiPad;
            joiPad.attachTo(this, mLayout);
        }
    }

    private void loadConfig(){
        String configPath;
        if (game.folder.startsWith(Environment.getExternalStorageDirectory().getAbsolutePath())){
            configPath = game.folder+"/configuration.json";
        } else {
            configPath = Environment.getExternalStorageDirectory().getAbsolutePath()+"/JoiPlay/games/"+game.id+"/configuration.json";
        }
        File configFile = new File(configPath);

        if (configFile.exists()){
            try {
                MKXPConfigurationParser.loadFromFile(configuration, configFile);
            } catch (Exception e){
                Log.d(TAG, Log.getStackTraceString(e));
            }
        }
    }

    void createUserDataFolders(String parentFolder){
        File tempFolder = new File(parentFolder+"/UserData/Temp");
        File dataFoler = new File(parentFolder+"/UserData/AppData");

        try {
            if (!tempFolder.exists()) tempFolder.mkdirs();
            if (!dataFoler.exists()) dataFoler.mkdirs();
        } catch (Exception e){
            Log.d(TAG, Log.getStackTraceString(e));
        }
    }

    void showErrorDialog(Throwable e){
        StackTraceElement causeElement = e.getStackTrace()[0];
        String errCode = e.getMessage()+"\n"+causeElement.getFileName()+":"+causeElement.getLineNumber()+"/"+causeElement.getClassName()+":"+causeElement.getMethodName();
        ErrorDialog errorDialog = new ErrorDialog();
        errorDialog.setTitle(R.string.error);
        errorDialog.setMessage(getContext().getResources().getString(R.string.error_message, errCode));
        errorDialog.setCloseButton(R.string.close, ()-> SDLActivity.mSingleton.finish());
        errorDialog.show(this);
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (joiPad != null) {
            if (joiPad.processGamepadEvent(event)) {
                return true;
            }
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    public boolean onGenericMotionEvent(MotionEvent event) {
        if (joiPad != null) {
            if (joiPad.processDPadEvent(event)) {
                return true;
            }
        }
        return super.onGenericMotionEvent(event);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }
}
