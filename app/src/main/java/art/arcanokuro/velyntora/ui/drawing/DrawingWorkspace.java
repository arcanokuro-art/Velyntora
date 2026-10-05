package art.arcanokuro.velyntora.ui.drawing;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

import art.arcanokuro.velyntora.ui.drawing.components.DrawingStatusBar;
import art.arcanokuro.velyntora.ui.drawing.components.DrawingToolbox;
import art.arcanokuro.velyntora.ui.drawing.components.DrawingTopBar;

/**
 * Composes Velyntora's Drawing environment.
 * Individual UI areas live in components so engine-backed behavior can be
 * connected without mixing navigation, tools, canvas and status controls.
 */
public final class DrawingWorkspace {
    private final Activity a;
    private final DrawingTopBar topBar;
    private final DrawingToolbox toolbox;
    private final DrawingStatusBar statusBar;

    public DrawingWorkspace(Activity activity){
        a=activity;
        topBar=new DrawingTopBar(activity);
        toolbox=new DrawingToolbox(activity);
        statusBar=new DrawingStatusBar(activity);
    }

    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(String source,Runnable onBack){
        String documentName=source==null?"[No guardado]":source;

        LinearLayout root=col();
        root.setBackgroundColor(Color.rgb(31,31,31));
        root.addView(topBar.createMenu(onBack,documentName),new LinearLayout.LayoutParams(-1,dp(42)));
        root.addView(topBar.createToolOptions(),new LinearLayout.LayoutParams(-1,dp(46)));

        LinearLayout body=row();
        body.addView(toolbox.create(),new LinearLayout.LayoutParams(dp(150),-1));
        body.addView(createCanvas(documentName),new LinearLayout.LayoutParams(0,-1,1));
        root.addView(body,new LinearLayout.LayoutParams(-1,0,1));

        root.addView(statusBar.create(),new LinearLayout.LayoutParams(-1,dp(52)));
        return root;
    }

    private View createCanvas(String documentName){
        FrameLayout canvasArea=new FrameLayout(a);
        canvasArea.setBackgroundColor(Color.rgb(92,92,92));

        TextView canvas=new TextView(a);
        canvas.setText(documentName);
        canvas.setTextColor(Color.rgb(90,90,90));
        canvas.setTextSize(14);
        canvas.setGravity(Gravity.CENTER);

        GradientDrawable paper=new GradientDrawable();
        paper.setColor(Color.rgb(245,245,245));
        paper.setStroke(dp(1),Color.rgb(120,120,120));
        canvas.setBackground(paper);

        canvasArea.addView(canvas,new FrameLayout.LayoutParams(dp(620),dp(430),Gravity.CENTER));
        return canvasArea;
    }

    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
    private LinearLayout col(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.VERTICAL);return l;}
}
