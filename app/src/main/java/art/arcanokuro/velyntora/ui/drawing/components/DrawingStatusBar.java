package art.arcanokuro.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;

public final class DrawingStatusBar {
    private final Activity a;
    private final int text=Color.rgb(235,235,235);
    public DrawingStatusBar(Activity activity){a=activity;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(){
        LinearLayout bar=row(); bar.setGravity(Gravity.CENTER_VERTICAL); bar.setPadding(dp(10),0,dp(10),0); bar.setBackgroundColor(Color.rgb(43,43,43));
        bar.addView(label("X: 0   Y: 0"),new LinearLayout.LayoutParams(dp(130),-1));
        bar.addView(label("620 × 430 px"),new LinearLayout.LayoutParams(dp(130),-1));
        LinearLayout palette=row();
        int[] colors={0xff000000,0xff7f7f7f,0xffffffff,0xffed1c24,0xffff7f27,0xffffc90e,0xff22b14c,0xff00a2e8,0xff3f48cc,0xffa349a4};
        for(int c:colors){View swatch=new View(a);GradientDrawable g=new GradientDrawable();g.setColor(c);g.setStroke(dp(1),Color.rgb(72,72,72));swatch.setBackground(g);LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(dp(28),dp(28));p.setMargins(dp(2),0,dp(2),0);palette.addView(swatch,p);}
        bar.addView(palette,new LinearLayout.LayoutParams(0,-1,1));
        TextView zoom=label("100%");zoom.setGravity(Gravity.CENTER);bar.addView(zoom,new LinearLayout.LayoutParams(dp(55),-1));
        SeekBar slider=new SeekBar(a);slider.setMax(400);slider.setProgress(100);bar.addView(slider,new LinearLayout.LayoutParams(dp(150),-2));
        return bar;
    }

    private TextView label(String value){TextView t=new TextView(a);t.setText(value);t.setTextColor(text);t.setTextSize(12);t.setGravity(Gravity.CENTER_VERTICAL);return t;}
    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
}
