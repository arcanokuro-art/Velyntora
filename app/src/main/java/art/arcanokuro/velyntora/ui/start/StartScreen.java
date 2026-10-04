package art.arcanokuro.velyntora.ui.start;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.*;

public final class StartScreen {
    private final Activity a;
    private final int bg=Color.rgb(13,20,32), text=Color.rgb(238,241,247), muted=Color.rgb(175,184,201);
    public StartScreen(Activity activity){a=activity;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(){
        LinearLayout root=col(); root.setBackgroundColor(bg); root.setPadding(dp(24),dp(12),dp(24),dp(12));
        root.addView(brand(),new LinearLayout.LayoutParams(-1,dp(78)));
        TextView q=txt("¿Qué quieres crear?",24,text,true); q.setGravity(Gravity.CENTER);
        root.addView(q,new LinearLayout.LayoutParams(-1,dp(50)));

        LinearLayout choices=row(); choices.setGravity(Gravity.CENTER);
        choices.addView(mode(false),new LinearLayout.LayoutParams(0,0,1));
        Space gap=new Space(a); choices.addView(gap,new LinearLayout.LayoutParams(dp(18),1));
        choices.addView(mode(true),new LinearLayout.LayoutParams(0,0,1));
        root.addView(choices,new LinearLayout.LayoutParams(-1,0,1));

        root.addView(recents(),new LinearLayout.LayoutParams(-1,dp(150)));
        LinearLayout footer=row(); footer.setGravity(Gravity.RIGHT|Gravity.CENTER_VERTICAL);
        footer.addView(outline("⚙  Preferencias de Velyntora"));
        Space fgap=new Space(a); footer.addView(fgap,new LinearLayout.LayoutParams(dp(12),1));
        footer.addView(outline("?  Ayuda"));
        root.addView(footer,new LinearLayout.LayoutParams(-1,dp(60)));
        return root;
    }

    private View brand(){
        LinearLayout l=col(); l.setGravity(Gravity.CENTER);
        TextView n=txt("VELYNTORΛ",34,Color.WHITE,false); n.setGravity(Gravity.CENTER); n.setLetterSpacing(.22f); l.addView(n);
        TextView s=txt("ARTE SIN LÍMITES",10,muted,false); s.setGravity(Gravity.CENTER); s.setLetterSpacing(.28f); l.addView(s); return l;
    }

    private View mode(boolean animation){
        FrameLayout card=new FrameLayout(a);
        GradientDrawable gd=new GradientDrawable(GradientDrawable.Orientation.TL_BR,
          animation?new int[]{Color.rgb(9,36,72),Color.rgb(14,24,40)}:new int[]{Color.rgb(59,22,72),Color.rgb(24,20,38)});
        gd.setCornerRadius(dp(14)); gd.setStroke(dp(1),animation?Color.rgb(33,137,255):Color.rgb(185,61,207)); card.setBackground(gd);

        // Exact supplied artwork will occupy this full bleed layer once stored as Android resources.
        TextView art=txt(animation?"ANIMACIÓN":"DIBUJO",12,animation?Color.rgb(68,151,255):Color.rgb(213,106,229),true);
        art.setAlpha(.16f); art.setGravity(animation?Gravity.RIGHT|Gravity.CENTER_VERTICAL:Gravity.LEFT|Gravity.CENTER_VERTICAL);
        card.addView(art,new FrameLayout.LayoutParams(-1,-1));

        LinearLayout content=col(); content.setGravity(Gravity.CENTER); content.setPadding(dp(34),dp(24),dp(34),dp(20));
        TextView icon=txt(animation?"▣":"✎",38,text,false); icon.setGravity(Gravity.CENTER); content.addView(icon);
        TextView title=txt(animation?"ANIMACIÓN":"DIBUJO",25,text,true); title.setGravity(Gravity.CENTER); content.addView(title);
        TextView desc=txt(animation?"Crea animaciones 2D, fotogramas\ny secuencias con todas las herramientas.":"Crea ilustraciones, edita imágenes\ny da vida a tus ideas.",15,Color.rgb(210,216,228),false);
        desc.setGravity(Gravity.CENTER); content.addView(desc);
        Space sp=new Space(a); content.addView(sp,new LinearLayout.LayoutParams(1,dp(15)));
        content.addView(primary(animation? "Crear animación":"Crear ilustración",animation),new LinearLayout.LayoutParams(-1,dp(50)));
        Space sp2=new Space(a); content.addView(sp2,new LinearLayout.LayoutParams(1,dp(10)));
        content.addView(outline(animation?"Abrir proyecto":"Abrir imagen"),new LinearLayout.LayoutParams(-1,dp(50)));
        card.addView(content,new FrameLayout.LayoutParams(-1,-1)); return card;
    }

    private View recents(){
        LinearLayout box=col(); box.setPadding(dp(15),dp(8),dp(15),dp(8)); box.setBackground(round(Color.rgb(16,25,39),Color.rgb(36,49,68),10));
        LinearLayout h=row(); TextView t=txt("Proyectos recientes",18,text,true); h.addView(t,new LinearLayout.LayoutParams(0,-2,1)); h.addView(outline("Ver más »"));
        box.addView(h,new LinearLayout.LayoutParams(-1,dp(44)));
        TextView empty=txt("Tus proyectos recientes aparecerán aquí.",14,muted,false); empty.setGravity(Gravity.CENTER);
        box.addView(empty,new LinearLayout.LayoutParams(-1,0,1)); return box;
    }

    private Button primary(String s,boolean blue){Button b=button(s); b.setTextColor(Color.WHITE); b.setTypeface(Typeface.DEFAULT,Typeface.BOLD); b.setBackground(round(blue?Color.rgb(35,126,244):Color.rgb(171,52,190),Color.TRANSPARENT,8)); return b;}
    private Button outline(String s){Button b=button(s); b.setTextColor(text); b.setBackground(round(Color.rgb(18,27,42),Color.rgb(81,95,120),8)); return b;}
    private Button button(String s){Button b=new Button(a);b.setText(s);b.setTextSize(14);b.setAllCaps(false);b.setPadding(dp(14),0,dp(14),0);return b;}
    private TextView txt(String s,int z,int c,boolean bold){TextView v=new TextView(a);v.setText(s);v.setTextSize(z);v.setTextColor(c);if(bold)v.setTypeface(Typeface.DEFAULT,Typeface.BOLD);return v;}
    private LinearLayout col(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.VERTICAL);return l;}
    private LinearLayout row(){LinearLayout l=new LinearLayout(a);l.setOrientation(LinearLayout.HORIZONTAL);return l;}
    private GradientDrawable round(int fill,int stroke,int r){GradientDrawable g=new GradientDrawable();g.setColor(fill);g.setCornerRadius(dp(r));if(stroke!=Color.TRANSPARENT)g.setStroke(dp(1),stroke);return g;}
}
