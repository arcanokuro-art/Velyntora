package app.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import app.velyntora.ui.drawing.DrawingState;

public final class DrawingToolbox {
    private final Activity a; private final DrawingState state; private final int text=Color.rgb(235,235,235);
    private TextView selected;
    private final String[][] icons={{"↖","✥","▭"},{"✎","⌫","T"},{"／⌁","▱","○"},{"▧","◈","⌕"},{"☝","▣",""}};
    private final String[][] names={{"Seleccionar","Mover","Rectángulo"},{"Pincel","Borrador","Texto"},{"Línea/Curva","Polígono","Elipse"},{"Selección rectangular","Transformar","Zoom"},{"Mano","Relleno",""}};
    public DrawingToolbox(Activity activity,DrawingState drawingState){a=activity;state=drawingState;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(){
        LinearLayout panel=col();panel.setPadding(dp(6),dp(8),dp(6),dp(8));panel.setBackgroundColor(Color.rgb(38,38,38));
        for(int r=0;r<icons.length;r++){LinearLayout line=row();for(int c=0;c<icons[r].length;c++){final String name=names[r][c];if(name.isEmpty()){View spacer=new View(a);line.addView(spacer,new LinearLayout.LayoutParams(0,dp(58),1));continue;}Button b=tool(icons[r][c]);b.setContentDescription(name);b.setOnClickListener(v->{state.setTool(name);selected.setText(name);});line.addView(b,new LinearLayout.LayoutParams(0,dp(58),1));}panel.addView(line,new LinearLayout.LayoutParams(-1,dp(58)));}
        selected=new TextView(a);selected.setText(state.tool());selected.setTextColor(text);selected.setTextSize(12);selected.setGravity(Gravity.CENTER);panel.addView(selected,new LinearLayout.LayoutParams(-1,dp(34)));
        return panel;
    }
    private Button tool(String v){Button b=new Button(a);b.setText(v);b.setTextColor(text);b.setTextSize(19);b.setAllCaps(false);b.setPadding(dp(4),0,dp(4),0);b.setMinWidth(0);b.setMinimumWidth(0);GradientDrawable g=new GradientDrawable();g.setColor(Color.TRANSPARENT);b.setBackground(g);return b;}
    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;} private LinearLayout col(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.VERTICAL);return l;}
}
