package art.arcanokuro.velyntora;

import android.os.Bundle;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private TextView text(String value, int sp) {
        TextView v = new TextView(this);
        v.setText(value); v.setTextSize(sp); v.setTextColor(Color.rgb(205,205,205));
        v.setPadding(14,10,14,10); return v;
    }
    private TextView title(String value) {
        TextView v=text(value,20); v.setTypeface(Typeface.DEFAULT,Typeface.BOLD); return v;
    }
    private LinearLayout column() {
        LinearLayout l=new LinearLayout(this); l.setOrientation(LinearLayout.VERTICAL); l.setPadding(14,10,14,10); return l;
    }
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        LinearLayout root=column(); root.setBackgroundColor(Color.rgb(45,45,45));
        root.addView(menuBar());

        LinearLayout body=new LinearLayout(this); body.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout left=column(); LinearLayout center=column(); LinearLayout right=column();
        body.addView(left,new LinearLayout.LayoutParams(0,-1,1));
        body.addView(center,new LinearLayout.LayoutParams(0,-1,2));
        body.addView(right,new LinearLayout.LayoutParams(0,-1,1));

        left.addView(title("Inicio"));
        left.addView(text("＋  Imagen nueva   Ctrl+N",17));
        left.addView(text("▣  Abrir imagen   Ctrl+O",17));
        Space gap=new Space(this); left.addView(gap,new LinearLayout.LayoutParams(1,45));
        left.addView(title("Comunidad"));
        String[] links={"Manual del usuario","Apoyar a Krita","Funciona con KDE","Código fuente","Primeros pasos","Comunidad de usuarios","Sitio web de Krita"};
        for(String s:links) left.addView(text(s,15));

        center.addView(title("Imágenes recientes"));
        TextView empty=text("Parece que no hay documentos abiertos recientemente",16);
        empty.setGravity(Gravity.CENTER);
        center.addView(empty,new LinearLayout.LayoutParams(-1,0,1));

        right.addView(title("Noticias"));
        TextView news=text("Puede activar las noticias de krita.org en varios idiomas con el menú superior.",15);
        news.setGravity(Gravity.CENTER); right.addView(news,new LinearLayout.LayoutParams(-1,0,1));

        root.addView(body,new LinearLayout.LayoutParams(-1,0,1));
        setContentView(root);
    }
    private View menuBar() {
        HorizontalScrollView scroll=new HorizontalScrollView(this);
        LinearLayout bar=new LinearLayout(this); bar.setOrientation(LinearLayout.HORIZONTAL);
        String[] menu={"Archivo","Editar","Ver","Imagen","Capa","Seleccionar","Filtro","Herramientas","Preferencias","Ventana","Ayuda"};
        for(String s:menu) bar.addView(text(s,14));
        scroll.addView(bar); return scroll;
    }
}
