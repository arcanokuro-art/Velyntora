package art.arcanokuro.velyntora;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import art.arcanokuro.velyntora.ui.start.StartScreen;

public class MainActivity extends Activity {
    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        int background = Color.rgb(13,20,32);
        getWindow().setStatusBarColor(background);
        getWindow().setNavigationBarColor(background);
        setContentView(new StartScreen(this).create());
    }
}
