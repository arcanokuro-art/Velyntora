package art.arcanokuro.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;

public final class DrawingTopBar {
    private final Activity a;
    private final int text=Color.rgb(235,235,235);
    public DrawingTopBar(Activity activity){a=activity;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View createMenu(Runnable onBack,String documentName){
        LinearLayout bar=row(); bar.setGravity(Gravity.CENTER_VERTICAL); bar.setPadding(dp(8),0,dp(8),0); bar.setBackgroundColor(Color.rgb(43,43,43));
        Button back=flat("‹"); back.setOnClickListener(v->onBack.run()); bar.addView(back,new LinearLayout.LayoutParams(dp(42),dp(36)));
        String[] menus={"Archivo","Editar","Ver","Imagen","Capa","Seleccionar","Filtros","Herramientas","Configuración","Ayuda"};
        for(String name:menus) bar.addView(flat(name),new LinearLayout.LayoutParams(-2,dp(36)));
        bar.addView(new Space(a),new LinearLayout.LayoutParams(0,1,1));
        TextView title=label("Velyntora — "+documentName,13); title.setGravity(Gravity.CENTER_VERTICAL|Gravity.RIGHT);
        bar.addView(title,new LinearLayout.LayoutParams(dp(210),-1));
        return bar;
    }

    public View createToolOptions(){
        LinearLayout bar=row(); bar.setGravity(Gravity.CENTER_VERTICAL); bar.setPadding(dp(10),0,dp(10),0); bar.setBackgroundColor(Color.rgb(37,37,37));
        bar.addView(label("Pincel: Básico",13)); bar.addView(space(18)); bar.addView(label("Tamaño",13));
        SeekBar size=new SeekBar(a); size.setMax(200); size.setProgress(40); bar.addView(size,new LinearLayout.LayoutParams(dp(170),-2));
        bar.addView(label("40 px",13)); bar.addView(space(20)); bar.addView(label("Opacidad 100%",13));
        return bar;
    }

    private Button flat(String value){Button b=new Button(a);b.setText(value);b.setTextColor(text);b.setTextSize(13);b.setAllCaps(false);b.setPadding(dp(7),0,dp(7),0);b.setMinWidth(0);b.setMinimumWidth(0);GradientDrawable g=new GradientDrawable();g.setColor(Color.TRANSPARENT);b.setBackground(g);return b;}
    private TextView label(String value,int size){TextView t=new TextView(a);t.setText(value);t.setTextColor(text);t.setTextSize(size);t.setGravity(Gravity.CENTER_VERTICAL);return t;}
    private Space space(int width){Space s=new Space(a);s.setLayoutParams(new LinearLayout.LayoutParams(dp(width),1));return s;}
    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
}
