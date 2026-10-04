package art.arcanokuro.velyntora;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;

public class MainActivity extends Activity {
    private final int BG = Color.rgb(13,20,32);
    private final int PANEL = Color.rgb(18,27,42);
    private final int TEXT = Color.rgb(235,238,245);
    private final int MUTED = Color.rgb(172,181,198);
    private int dp(int v){ return Math.round(v * getResources().getDisplayMetrics().density); }

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(BG);
        getWindow().setNavigationBarColor(BG);

        LinearLayout root = column();
        root.setBackgroundColor(BG);
        root.setPadding(dp(20), dp(14), dp(20), dp(12));

        root.addView(brand(), new LinearLayout.LayoutParams(-1, dp(86)));

        TextView question = label("¿Qué quieres crear?", 25, TEXT, true);
        question.setGravity(Gravity.CENTER);
        root.addView(question, new LinearLayout.LayoutParams(-1, dp(50)));

        LinearLayout hero = row();
        hero.setGravity(Gravity.CENTER);
        hero.addView(artPanel("DIBUJO", "Crea ilustraciones, edita imágenes\ny da vida a tus ideas.",
                "Crear ilustración", "Abrir imagen", false),
                new LinearLayout.LayoutParams(0, dp(330), 1));
        Space centerGap = new Space(this);
        hero.addView(centerGap, new LinearLayout.LayoutParams(dp(18), 1));
        hero.addView(artPanel("ANIMACIÓN", "Crea animaciones 2D, fotogramas\ny secuencias con todas las herramientas.",
                "Crear animación", "Abrir proyecto", true),
                new LinearLayout.LayoutParams(0, dp(330), 1));
        root.addView(hero, new LinearLayout.LayoutParams(-1, 0, 1));

        root.addView(recentProjects(), new LinearLayout.LayoutParams(-1, dp(145)));

        LinearLayout footer = row();
        footer.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        footer.addView(secondaryButton("⚙  Preferencias de Velyntora"));
        Space fg = new Space(this); footer.addView(fg, new LinearLayout.LayoutParams(dp(12),1));
        footer.addView(secondaryButton("?  Ayuda"));
        root.addView(footer, new LinearLayout.LayoutParams(-1, dp(62)));

        setContentView(root);
    }

    private View brand() {
        LinearLayout box = column(); box.setGravity(Gravity.CENTER);
        TextView name = label("VELYNTORΛ", 35, Color.WHITE, false);
        name.setGravity(Gravity.CENTER); name.setLetterSpacing(.22f);
        box.addView(name);
        TextView tag = label("ARTE SIN LÍMITES", 11, MUTED, false);
        tag.setGravity(Gravity.CENTER); tag.setLetterSpacing(.25f);
        box.addView(tag);
        return box;
    }

    private View artPanel(String title, String description, String primary, String secondary, boolean blue) {
        FrameLayout frame = new FrameLayout(this);
        GradientDrawable bg = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                blue ? new int[]{Color.rgb(10,34,66), Color.rgb(16,23,38)}
                     : new int[]{Color.rgb(55,22,67), Color.rgb(25,22,39)});
        bg.setCornerRadius(dp(14));
        bg.setStroke(dp(1), blue ? Color.rgb(32,132,255) : Color.rgb(177,55,198));
        frame.setBackground(bg);

        TextView imageSlot = label(blue ? "IMAGEN · ANIMACIÓN" : "IMAGEN · DIBUJO", 12,
                blue ? Color.rgb(79,159,255) : Color.rgb(210,105,226), true);
        imageSlot.setGravity(blue ? Gravity.RIGHT|Gravity.CENTER_VERTICAL : Gravity.LEFT|Gravity.CENTER_VERTICAL);
        imageSlot.setAlpha(.35f);
        frame.addView(imageSlot, new FrameLayout.LayoutParams(-1,-1));

        LinearLayout content = column();
        content.setGravity(Gravity.CENTER);
        content.setPadding(dp(28),dp(30),dp(28),dp(22));
        TextView t=label(title,26,TEXT,true); t.setGravity(Gravity.CENTER); content.addView(t);
        TextView d=label(description,15,Color.rgb(205,211,223),false); d.setGravity(Gravity.CENTER);
        content.addView(d);
        Space s=new Space(this); content.addView(s,new LinearLayout.LayoutParams(1,dp(18)));
        content.addView(primaryButton(primary, blue), new LinearLayout.LayoutParams(-1,dp(52)));
        Space s2=new Space(this); content.addView(s2,new LinearLayout.LayoutParams(1,dp(12)));
        content.addView(secondaryButton(secondary), new LinearLayout.LayoutParams(-1,dp(52)));
        frame.addView(content,new FrameLayout.LayoutParams(-1,-1));
        return frame;
    }

    private View recentProjects() {
        LinearLayout section = column();
        GradientDrawable bg = rounded(PANEL, Color.rgb(38,50,68), 12);
        section.setBackground(bg); section.setPadding(dp(16),dp(10),dp(16),dp(10));

        LinearLayout header=row();
        TextView title=label("Proyectos recientes",18,TEXT,true);
        header.addView(title,new LinearLayout.LayoutParams(0,-2,1));
        header.addView(secondaryButton("Ver más »"));
        section.addView(header,new LinearLayout.LayoutParams(-1,dp(44)));

        TextView empty=label("Tus proyectos recientes aparecerán aquí.",14,MUTED,false);
        empty.setGravity(Gravity.CENTER);
        section.addView(empty,new LinearLayout.LayoutParams(-1,0,1));
        return section;
    }

    private Button primaryButton(String text, boolean blue) {
        Button b=button(text);
        GradientDrawable g=rounded(blue?Color.rgb(30,124,244):Color.rgb(170,52,190), Color.TRANSPARENT, 9);
        b.setBackground(g); b.setTextColor(Color.WHITE); b.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        return b;
    }

    private Button secondaryButton(String text) {
        Button b=button(text);
        b.setBackground(rounded(Color.rgb(20,29,44),Color.rgb(87,100,124),8));
        b.setTextColor(TEXT); return b;
    }

    private Button button(String text) {
        Button b=new Button(this); b.setText(text); b.setTextSize(14); b.setAllCaps(false);
        b.setPadding(dp(14),0,dp(14),0); return b;
    }
    private TextView label(String s,int sp,int color,boolean bold){
        TextView v=new TextView(this); v.setText(s); v.setTextSize(sp); v.setTextColor(color);
        if(bold)v.setTypeface(Typeface.DEFAULT,Typeface.BOLD); return v;
    }
    private LinearLayout column(){ LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.VERTICAL); return l; }
    private LinearLayout row(){ LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.HORIZONTAL); return l; }
    private GradientDrawable rounded(int fill,int stroke,int radius){
        GradientDrawable g=new GradientDrawable(); g.setColor(fill); g.setCornerRadius(dp(radius));
        if(stroke!=Color.TRANSPARENT)g.setStroke(dp(1),stroke); return g;
    }
}
