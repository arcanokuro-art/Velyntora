package art.arcanokuro.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

import art.arcanokuro.velyntora.ui.drawing.DrawingState;

public final class DrawingCanvas implements DrawingState.Listener {
    private final Activity a;
    private final DrawingState state;
    private FrameLayout area;
    private TextView paper;

    public DrawingCanvas(Activity activity,DrawingState drawingState){a=activity;state=drawingState;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(String documentName){
        area=new FrameLayout(a);
        area.setBackgroundColor(Color.rgb(92,92,92));

        paper=new TextView(a);
        paper.setText(documentName);
        paper.setTextColor(Color.rgb(90,90,90));
        paper.setTextSize(14);
        paper.setGravity(Gravity.CENTER);
        GradientDrawable background=new GradientDrawable();
        background.setColor(Color.rgb(245,245,245));
        background.setStroke(dp(1),Color.rgb(120,120,120));
        paper.setBackground(background);
        area.addView(paper,new FrameLayout.LayoutParams(dp(620),dp(430),Gravity.CENTER));
        updateZoom();
        return area;
    }

    @Override public void onDrawingStateChanged(DrawingState ignored){updateZoom();}

    private void updateZoom(){
        if(paper==null)return;
        float scale=state.zoom()/100f;
        paper.setScaleX(scale);
        paper.setScaleY(scale);
    }
}
