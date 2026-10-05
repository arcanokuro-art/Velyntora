package art.arcanokuro.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;

public final class DrawingToolbox {
    private final Activity a;
    private final int text=Color.rgb(235,235,235);
    public DrawingToolbox(Activity activity){a=activity;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(){
        LinearLayout panel=col(); panel.setPadding(dp(6),dp(8),dp(6),dp(8)); panel.setBackgroundColor(Color.rgb(38,38,38));
        String[][] tools={{"↖","✥","▭"},{"✎","⌫","T"},{"／⌁","▱","○"},{"▧","◈","⌕"},{"☝","▣","⌁"}};
        for(String[] row:tools){
            LinearLayout line=row();
            for(String tool:row){Button b=tool(tool);line.addView(b,new LinearLayout.LayoutParams(0,dp(58),1));}
            panel.addView(line,new LinearLayout.LayoutParams(-1,dp(58)));
        }
        TextView selected=new TextView(a); selected.setText("Línea/Curva"); selected.setTextColor(text); selected.setTextSize(12); selected.setGravity(Gravity.CENTER);
        panel.addView(selected,new LinearLayout.LayoutParams(-1,dp(34)));
        return panel;
    }

    private Button tool(String value){Button b=new Button(a);b.setText(value);b.setTextColor(text);b.setTextSize(19);b.setAllCaps(false);b.setPadding(dp(4),0,dp(4),0);b.setMinWidth(0);b.setMinimumWidth(0);GradientDrawable g=new GradientDrawable();g.setColor(Color.TRANSPARENT);b.setBackground(g);return b;}
    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
    private LinearLayout col(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.VERTICAL);return l;}
}
