package art.arcanokuro.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import art.arcanokuro.velyntora.ui.drawing.DrawingState;

public final class DrawingStatusBar implements DrawingState.Listener {
    private final Activity a; private final DrawingState state; private final int text=Color.rgb(235,235,235);
    private TextView zoomLabel,coordsLabel;
    public DrawingStatusBar(Activity activity,DrawingState drawingState){a=activity;state=drawingState;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}
    public View create(){
        LinearLayout bar=row();bar.setGravity(Gravity.CENTER_VERTICAL);bar.setPadding(dp(10),0,dp(10),0);bar.setBackgroundColor(Color.rgb(43,43,43));
        coordsLabel=label("X: "+state.pointerX()+"   Y: "+state.pointerY());bar.addView(coordsLabel,new LinearLayout.LayoutParams(dp(130),-1));bar.addView(label("620 × 430 px"),new LinearLayout.LayoutParams(dp(130),-1));
        LinearLayout palette=row();int[] colors={0xff000000,0xff7f7f7f,0xffffffff,0xffed1c24,0xffff7f27,0xffffc90e,0xff22b14c,0xff00a2e8,0xff3f48cc,0xffa349a4};
        for(int color:colors){View swatch=new View(a);GradientDrawable g=new GradientDrawable();g.setColor(color);g.setStroke(dp(1),Color.rgb(72,72,72));swatch.setBackground(g);swatch.setOnClickListener(v->state.setColor(color));LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(dp(28),dp(28));p.setMargins(dp(2),0,dp(2),0);palette.addView(swatch,p);}
        bar.addView(palette,new LinearLayout.LayoutParams(0,-1,1));
        zoomLabel=label(state.zoom()+"%");zoomLabel.setGravity(Gravity.CENTER);bar.addView(zoomLabel,new LinearLayout.LayoutParams(dp(55),-1));
        SeekBar slider=new SeekBar(a);slider.setMax(390);slider.setProgress(state.zoom()-10);slider.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar b,int p,boolean u){state.setZoom(p+10);zoomLabel.setText(state.zoom()+"%");}public void onStartTrackingTouch(SeekBar b){}public void onStopTrackingTouch(SeekBar b){}});bar.addView(slider,new LinearLayout.LayoutParams(dp(150),-2));
        return bar;
    }
    @Override public void onDrawingStateChanged(DrawingState s){if(coordsLabel!=null)coordsLabel.setText("X: "+s.pointerX()+"   Y: "+s.pointerY());if(zoomLabel!=null)zoomLabel.setText(s.zoom()+"%");}
    private TextView label(String v){TextView t=new TextView(a);t.setText(v);t.setTextColor(text);t.setTextSize(12);t.setGravity(Gravity.CENTER_VERTICAL);return t;}private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
}
