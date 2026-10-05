package art.arcanokuro.velyntora.ui.drawing;

import android.app.Activity;
import android.graphics.Color;
import android.view.View;
import android.widget.LinearLayout;

import art.arcanokuro.velyntora.ui.drawing.components.DrawingCanvas;
import art.arcanokuro.velyntora.ui.drawing.components.DrawingStatusBar;
import art.arcanokuro.velyntora.ui.drawing.components.DrawingToolbox;
import art.arcanokuro.velyntora.ui.drawing.components.DrawingTopBar;

public final class DrawingWorkspace {
    private final Activity a;
    private final DrawingState state;
    private final DrawingTopBar topBar;
    private final DrawingToolbox toolbox;
    private final DrawingStatusBar statusBar;
    private final DrawingCanvas canvas;

    public DrawingWorkspace(Activity activity){
        a=activity;
        state=new DrawingState();
        topBar=new DrawingTopBar(activity,state);
        toolbox=new DrawingToolbox(activity,state);
        statusBar=new DrawingStatusBar(activity,state);
        canvas=new DrawingCanvas(activity,state);
        state.addListener(canvas);
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
        body.addView(canvas.create(documentName),new LinearLayout.LayoutParams(0,-1,1));
        root.addView(body,new LinearLayout.LayoutParams(-1,0,1));

        root.addView(statusBar.create(),new LinearLayout.LayoutParams(-1,dp(52)));
        return root;
    }

    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
    private LinearLayout col(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.VERTICAL);return l;}
}
