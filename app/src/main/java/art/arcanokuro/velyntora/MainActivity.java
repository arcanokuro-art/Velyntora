package art.arcanokuro.velyntora;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.content.Intent;
import android.net.Uri;
import android.database.Cursor;
import android.provider.OpenableColumns;
import art.arcanokuro.velyntora.ui.start.StartScreen;

public class MainActivity extends Activity {
    private StartScreen startScreen;

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        int background = Color.rgb(13,20,32);
        getWindow().setStatusBarColor(background);
        getWindow().setNavigationBarColor(background);
        startScreen = new StartScreen(this);
        setContentView(startScreen.create());
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode,resultCode,data);
        if(resultCode!=RESULT_OK || data==null) return;
        Uri uri=data.getData();
        if(uri==null) return;
        boolean animation=requestCode==2002;
        if(requestCode==2001 || requestCode==2002) {
            try {
                getContentResolver().takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            } catch (SecurityException ignored) {}
            setContentView(startScreen.createWorkspace(animation,displayName(uri)));
        }
    }
    private String displayName(Uri uri) {
        Cursor cursor=null;
        try {
            cursor=getContentResolver().query(uri,new String[]{OpenableColumns.DISPLAY_NAME},null,null,null);
            if(cursor!=null && cursor.moveToFirst()) {
                int index=cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if(index>=0) {
                    String name=cursor.getString(index);
                    if(name!=null && !name.trim().isEmpty()) return name;
                }
            }
        } catch (RuntimeException ignored) {
        } finally {
            if(cursor!=null) cursor.close();
        }
        String fallback=uri.getLastPathSegment();
        return fallback==null ? "Documento seleccionado" : fallback;
    }
}

