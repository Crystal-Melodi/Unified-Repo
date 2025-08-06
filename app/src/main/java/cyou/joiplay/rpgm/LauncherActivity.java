package cyou.joiplay.rpgm;

import android.app.Activity;
import android.content.ComponentName;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.text.Html;
import android.text.method.LinkMovementMethod;
import android.util.Log;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.TextView;
import cyou.joiplay.commons.file.InputStreamUtils;


public class LauncherActivity extends Activity {
    private final static String TAG = "LauncherActivity";
    private boolean shouldHide = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.rpgm_launcher);

        TextView versionText = findViewById(R.id.launcher_version_textview);
        TextView infoText = findViewById(R.id.launcher_info_textview);
        TextView licenseText = findViewById(R.id.launcher_license_textview);
        CheckBox hideCheckBox = findViewById(R.id.launcher_hide_checkbox);
        Button closeButton = findViewById(R.id.launcher_close_button);

        versionText.setText(BuildConfig.VERSION_NAME);

        infoText.setLinksClickable(true);
        infoText.setMovementMethod(LinkMovementMethod.getInstance());

        licenseText.setLinksClickable(true);
        licenseText.setMovementMethod(LinkMovementMethod.getInstance());

        try{
            String infoHTML = InputStreamUtils.inputStreamToString(getAssets().open("html/info.html"));
            String licenseHTML = InputStreamUtils.inputStreamToString(getAssets().open("html/license.html"));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N){
                infoText.setText(Html.fromHtml(infoHTML, Html.FROM_HTML_MODE_COMPACT));
                licenseText.setText(Html.fromHtml(licenseHTML, Html.FROM_HTML_MODE_LEGACY));
            } else {
                infoText.setText(Html.fromHtml(infoHTML));
                licenseText.setText(Html.fromHtml(licenseHTML));
            }
        } catch (Exception e){
            Log.d(TAG, Log.getStackTraceString(e));
        }

        hideCheckBox.setOnCheckedChangeListener((compoundButton, b) -> shouldHide = b);

        closeButton.setOnClickListener(view -> {
            if (shouldHide){
                PackageManager pm = getPackageManager();
                pm.setComponentEnabledSetting(new ComponentName(this, LauncherActivity.class),
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP);
            }
            finishAffinity();
        });
    }
}
