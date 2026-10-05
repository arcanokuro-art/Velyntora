package art.arcanokuro.velyntora.ui.drawing;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;

/**
 * Drawing workspace ported from the Velyntora-Z Drawing UI.
 * This is the Android application-side shell; engine-backed actions are
 * connected progressively without changing the approved StartScreen.
 */
public final class DrawingWorkspace {
    private final Activity a;
    private final int bg=Color.rgb(31,31,31);
    private final int panel=Color.rgb(43,43,43);
    private final int line=Color.rgb(72,72,72);
    private final int text=Color.rgb(235,235,235);

    public DrawingWorkspace(Activity activity){ a=activity; }
    private int dp(int v){ return Math.round(v*a.getResources().getDisplayMetrics().density); }

    public View create(String source, Runnable onBack) {
        LinearLayout root=col();
        root.setBackgroundColor(bg);

        root.addView(menuBar(onBack),new LinearLayout.LayoutParams(-1,dp(42)));
        root.addView(toolOptions(),new LinearLayout.LayoutParams(-1,dp(46)));

        LinearLayout body=row();
        body.addView(toolbox(),new LinearLayout.LayoutParams(dp(150),-1));

        FrameLayout canvasArea=new FrameLayout(a);
        canvasArea.setBackgroundColor(Color.rgb(92,92,92));
        TextView canvas=new TextView(a);
        canvas.setText(source==null ? "[No guardado]" : source);
        canvas.setTextColor(Color.rgb(90,90,90));
        canvas.setTextSize(14);
        canvas.setGravity(Gravity.CENTER);
        GradientDrawable paper=new GradientDrawable();
        paper.setColor(Color.rgb(245,245,245));
        paper.setStroke(dp(1),Color.rgb(120,120,120));
        canvas.setBackground(paper);
        FrameLayout.LayoutParams cp=new FrameLayout.LayoutParams(dp(620),dp(430),Gravity.CENTER);
        canvasArea.addView(canvas,cp);
        body.addView(canvasArea,new LinearLayout.LayoutParams(0,-1,1));

        root.addView(body,new LinearLayout.LayoutParams(-1,0,1));
        root.addView(bottomBar(),new LinearLayout.LayoutParams(-1,dp(52)));
        return root;
    }

    private View menuBar(Runnable onBack) {
        LinearLayout bar=row();
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(8),0,dp(8),0);
        bar.setBackgroundColor(panel);
        Button back=flat("‹");
        back.setOnClickListener(v->onBack.run());
        bar.addView(back,new LinearLayout.LayoutParams(dp(42),dp(36)));
        String[] menus={"Archivo","Editar","Ver","Imagen","Capa","Seleccionar","Filtros","Herramientas","Configuración","Ayuda"};
        for(String name:menus) bar.addView(flat(name),new LinearLayout.LayoutParams(-2,dp(36)));
        Space space=new Space(a);
        bar.addView(space,new LinearLayout.LayoutParams(0,1,1));
        TextView title=label("Velyntora — [No guardado]",13);
        title.setGravity(Gravity.CENTER_VERTICAL|Gravity.RIGHT);
        bar.addView(title,new LinearLayout.LayoutParams(dp(210),-1));
        return bar;
    }

    private View toolOptions() {
        LinearLayout bar=row();
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(10),0,dp(10),0);
        bar.setBackgroundColor(Color.rgb(37,37,37));
        bar.addView(label("Pincel: Básico",13));
        bar.addView(gap(18));
        bar.addView(label("Tamaño",13));
        SeekBar size=new SeekBar(a); size.setMax(200); size.setProgress(40);
        bar.addView(size,new LinearLayout.LayoutParams(dp(170),-2));
        bar.addView(label("40 px",13));
        bar.addView(gap(20));
        bar.addView(label("Opacidad 100%",13));
        return bar;
    }

    private View toolbox() {
        LinearLayout panelView=col();
        panelView.setPadding(dp(6),dp(8),dp(6),dp(8));
        panelView.setBackgroundColor(Color.rgb(38,38,38));
        String[][] tools={
                {"↖","✥","▭"},
                {"✎","⌫","T"},
                {"／⌁","▱","○"},
                {"▧","◈","⌕"},
                {"☝","▣","⌁"}
        };
        for(String[] r:tools){
            LinearLayout lineView=row();
            for(String tool:r){
                Button b=flat(tool);
                b.setTextSize(19);
                lineView.addView(b,new LinearLayout.LayoutParams(0,dp(58),1));
            }
            panelView.addView(lineView,new LinearLayout.LayoutParams(-1,dp(58)));
        }
        TextView selected=label("Línea/Curva",12);
        selected.setGravity(Gravity.CENTER);
        panelView.addView(selected,new LinearLayout.LayoutParams(-1,dp(34)));
        return panelView;
    }

    private View bottomBar() {
        LinearLayout bar=row();
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(10),0,dp(10),0);
        bar.setBackgroundColor(panel);
        TextView coords=label("X: 0   Y: 0",12);
        bar.addView(coords,new LinearLayout.LayoutParams(dp(130),-1));
        TextView size=label("620 × 430 px",12);
        bar.addView(size,new LinearLayout.LayoutParams(dp(130),-1));

        LinearLayout palette=row();
        int[] colors={0xff000000,0xff7f7f7f,0xffffffff,0xffed1c24,0xffff7f27,0xffffc90e,0xff22b14c,0xff00a2e8,0xff3f48cc,0xffa349a4};
        for(int c:colors){
            View swatch=new View(a);
            GradientDrawable gd=new GradientDrawable(); gd.setColor(c); gd.setStroke(dp(1),line);
            swatch.setBackground(gd);
            LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(dp(28),dp(28)); p.setMargins(dp(2),0,dp(2),0);
            palette.addView(swatch,p);
        }
        bar.addView(palette,new LinearLayout.LayoutParams(0,-1,1));

        TextView zoom=label("100%",12);
        zoom.setGravity(Gravity.CENTER);
        bar.addView(zoom,new LinearLayout.LayoutParams(dp(55),-1));
        SeekBar zoomBar=new SeekBar(a); zoomBar.setMax(400); zoomBar.setProgress(100);
        bar.addView(zoomBar,new LinearLayout.LayoutParams(dp(150),-2));
        return bar;
    }

    private Button flat(String value){
        Button b=new Button(a);
        b.setText(value); b.setTextColor(text); b.setTextSize(13); b.setAllCaps(false);
        b.setPadding(dp(7),0,dp(7),0); b.setMinWidth(0); b.setMinimumWidth(0);
        GradientDrawable gd=new GradientDrawable(); gd.setColor(Color.TRANSPARENT);
        b.setBackground(gd);
        return b;
    }
    private TextView label(String value,int size){ TextView t=new TextView(a); t.setText(value); t.setTextColor(text); t.setTextSize(size); t.setGravity(Gravity.CENTER_VERTICAL); return t; }
    private Space gap(int width){ Space s=new Space(a); s.setLayoutParams(new LinearLayout.LayoutParams(dp(width),1)); return s; }
    private LinearLayout row(){ LinearLayout l=new LinearLayout(a); l.setOrientation(LinearLayout.HORIZONTAL); return l; }
    private LinearLayout col(){ LinearLayout l=new LinearLayout(a); l.setOrientation(LinearLayout.VERTICAL); return l; }
}
