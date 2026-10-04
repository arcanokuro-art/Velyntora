package art.arcanokuro.velyntora;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.content.Intent;
import android.net.Uri;
import android.database.Cursor;
import android.provider.OpenableColumns;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import art.arcanokuro.velyntora.ui.start.StartScreen;

public class MainActivity extends Activity {
    private StartScreen startScreen;
    private boolean workspaceOpen=false;
    private boolean animationMode=false;
    private String openedDocument=null;
    private String openedDocumentUri=null;
    private String infoPage=null;

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        int background = Color.rgb(13,20,32);
        configureAdaptiveSystemBars(background);
        startScreen = new StartScreen(this);
        if(state!=null && state.getString("infoPage")!=null) {
            infoPage=state.getString("infoPage");
            setContentView(startScreen.createInfoPage(infoPage));
        } else if(state!=null && state.getBoolean("workspaceOpen",false)) {
            workspaceOpen=true;
            animationMode=state.getBoolean("animationMode",false);
            openedDocument=state.getString("openedDocument");
            openedDocumentUri=state.getString("openedDocumentUri");
            setContentView(startScreen.createWorkspace(animationMode,openedDocument));
        } else {
            setContentView(startScreen.create());
        }
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
            showWorkspace(animation,displayName(uri),uri.toString());
        }
    }

    public void showHome() {
        workspaceOpen=false;
        animationMode=false;
        openedDocument=null;
        openedDocumentUri=null;
        infoPage=null;
        setContentView(startScreen.create());
    }

    public void showWorkspace(boolean animation, String document) {
        showWorkspace(animation,document,null);
    }

    public void showWorkspace(boolean animation, String document, String documentUri) {
        workspaceOpen=true;
        animationMode=animation;
        openedDocument=document;
        openedDocumentUri=documentUri;
        infoPage=null;
        setContentView(startScreen.createWorkspace(animationMode,openedDocument));
    }

    public void showInfo(String page) {
        workspaceOpen=false;
        openedDocument=null;
        openedDocumentUri=null;
        infoPage=page;
        setContentView(startScreen.createInfoPage(page));
    }

    @Override public void onBackPressed() {
        // En las pantallas internas, Atrás siempre vuelve al inicio de Velyntora
        // en lugar de cerrar inesperadamente la aplicación.
        if(workspaceOpen || infoPage!=null) {
            showHome();
            return;
        }
        super.onBackPressed();
    }

    @Override protected void onSaveInstanceState(Bundle outState) {
        outState.putBoolean("workspaceOpen",workspaceOpen);
        outState.putBoolean("animationMode",animationMode);
        outState.putString("openedDocument",openedDocument);
        outState.putString("openedDocumentUri",openedDocumentUri);
        outState.putString("infoPage",infoPage);
        super.onSaveInstanceState(outState);
    }

    /**
     * Conserva el comportamiento adaptable de Krita en Android:
     * Velyntora usa el área disponible mientras las barras del sistema están
     * visibles y recupera automáticamente el espacio cuando Android las oculta.
     * No se fuerza immersive/fullscreen; Android sigue controlando sus barras.
     */
    private void configureAdaptiveSystemBars(int background) {
        Window window=getWindow();
        window.setStatusBarColor(background);
        window.setNavigationBarColor(background);

        // false = el contenido se mide dentro del área útil del sistema.
        // Al aparecer/desaparecer las barras, Android vuelve a medir la vista raíz.
        if(android.os.Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(true);
            WindowInsetsController controller=window.getInsetsController();
            if(controller!=null) {
                controller.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_DEFAULT);
            }
        } else {
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);
        }

        // Solicita una nueva medición cuando cambien los insets del sistema.
        window.getDecorView().setOnApplyWindowInsetsListener((view,insets) -> {
            view.requestLayout();
            return view.onApplyWindowInsets(insets);
        });
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

