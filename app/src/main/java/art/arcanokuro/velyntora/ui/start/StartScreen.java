package art.arcanokuro.velyntora.ui.start;

import android.app.Activity;
import art.arcanokuro.velyntora.MainActivity;
import android.graphics.Color;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.content.Intent;
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
        Button preferences=outline("⚙  Preferencias de Velyntora");
        preferences.setOnClickListener(v -> showInfo("preferences"));
        footer.addView(preferences);
        Space fgap=new Space(a); footer.addView(fgap,new LinearLayout.LayoutParams(dp(12),1));
        Button help=outline("?  Ayuda");
        help.setOnClickListener(v -> showInfo("help"));
        footer.addView(help);
        root.addView(footer,new LinearLayout.LayoutParams(-1,dp(60)));
        return root;
    }

    public View createInfoPage(String pageId){
        boolean preferences="preferences".equals(pageId);
        String titleText=preferences?"Preferencias de Velyntora":"Ayuda";
        String bodyText=preferences?"Las opciones de Velyntora se configurarán aquí.":"Ayuda y documentación de Velyntora.";
        LinearLayout page=col();
        page.setBackgroundColor(bg);
        page.setPadding(dp(40),dp(32),dp(40),dp(32));
        page.setGravity(Gravity.CENTER);
        TextView title=txt(titleText,28,text,true);
        title.setGravity(Gravity.CENTER);
        page.addView(title,new LinearLayout.LayoutParams(-1,dp(70)));
        TextView body=txt(bodyText,16,muted,false);
        body.setGravity(Gravity.CENTER);
        page.addView(body,new LinearLayout.LayoutParams(-1,dp(70)));
        Button back=outline("Volver al inicio");
        back.setOnClickListener(v -> showHome());
        LinearLayout.LayoutParams bp=new LinearLayout.LayoutParams(dp(240),dp(52));
        bp.gravity=Gravity.CENTER_HORIZONTAL;
        page.addView(back,bp);
        return page;
    }

    private View brand(){
        FrameLayout box=new FrameLayout(a);
        ImageView logo=new ImageView(a);
        logo.setImageBitmap(loadTransparentLogo());
        logo.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        box.addView(logo,new FrameLayout.LayoutParams(-1,-1));
        return box;
    }

    private Bitmap loadTransparentLogo(){
        Bitmap source=BitmapFactory.decodeResource(a.getResources(), art.arcanokuro.velyntora.R.drawable.velyntora_logo)
                .copy(Bitmap.Config.ARGB_8888,true);
        int w=source.getWidth(), h=source.getHeight();
        int[] pixels=new int[w*h];
        source.getPixels(pixels,0,w,0,0,w,h);
        for(int i=0;i<pixels.length;i++){
            int p=pixels[i];
            int r=Color.red(p), g=Color.green(p), b=Color.blue(p);
            // El fondo negro del archivo original se vuelve totalmente transparente.
            // Conserva las letras blancas y la A violeta.
            if(r<28 && g<28 && b<28) pixels[i]=Color.TRANSPARENT;
        }
        source.setPixels(pixels,0,w,0,0,w,h);
        return source;
    }

    private View mode(boolean animation){
        FrameLayout card=new FrameLayout(a);
        GradientDrawable gd=new GradientDrawable(GradientDrawable.Orientation.TL_BR,
          animation?new int[]{Color.rgb(9,36,72),Color.rgb(14,24,40)}:new int[]{Color.rgb(59,22,72),Color.rgb(24,20,38)});
        gd.setCornerRadius(dp(14)); gd.setStroke(dp(1),animation?Color.rgb(33,137,255):Color.rgb(185,61,207)); card.setBackground(gd);

        // Capa reservada para la ilustración exacta del modo. Se mantiene separada
        // del contenido para poder posicionarla a izquierda/derecha sin mover los botones.
        FrameLayout artLayer=new FrameLayout(a);
        artLayer.setClipToPadding(false);
        ImageView artwork=new ImageView(a);
        int artId=a.getResources().getIdentifier(animation?"start_animation":"start_drawing","drawable",a.getPackageName());
        if(artId!=0){
            artwork.setImageResource(artId);
            artwork.setScaleType(ImageView.ScaleType.CENTER_CROP);
            artwork.setAlpha(1f);

            // Las dos ilustraciones usan exactamente la misma geometría.
            // Dibujo queda anclada al exterior izquierdo y Animación al exterior derecho,
            // produciendo la composición espejo sin desplazamientos manuales.
            int artWidth=Math.round(a.getResources().getDisplayMetrics().widthPixels*0.36f);
            artWidth=Math.max(dp(220),Math.min(dp(420),artWidth));
            FrameLayout.LayoutParams artParams=new FrameLayout.LayoutParams(artWidth,-1);
            artParams.gravity=animation
                    ? Gravity.RIGHT|Gravity.CENTER_VERTICAL
                    : Gravity.LEFT|Gravity.CENTER_VERTICAL;
            artLayer.addView(artwork,artParams);
        }
        card.addView(artLayer,new FrameLayout.LayoutParams(-1,-1));

        LinearLayout content=col(); content.setGravity(Gravity.CENTER);
        content.setPadding(animation?dp(26):dp(150),dp(24),animation?dp(150):dp(26),dp(20));
        TextView icon=txt(animation?"▣":"✎",38,text,false); icon.setGravity(Gravity.CENTER); content.addView(icon);
        TextView title=txt(animation?"ANIMACIÓN":"DIBUJO",25,text,true); title.setGravity(Gravity.CENTER); content.addView(title);
        TextView desc=txt(animation?"Crea animaciones 2D, fotogramas\ny secuencias con todas las herramientas.":"Crea ilustraciones, edita imágenes\ny da vida a tus ideas.",15,Color.rgb(210,216,228),false);
        desc.setGravity(Gravity.CENTER); content.addView(desc);
        Space sp=new Space(a); content.addView(sp,new LinearLayout.LayoutParams(1,dp(15)));
        Button create=primary(animation? "Crear animación":"Crear ilustración",animation);
        create.setOnClickListener(v -> openWorkspace(animation));
        content.addView(create,new LinearLayout.LayoutParams(-1,dp(50)));
        Space sp2=new Space(a); content.addView(sp2,new LinearLayout.LayoutParams(1,dp(10)));
        Button open=outline(animation?"Abrir proyecto":"Abrir imagen");
        open.setOnClickListener(v -> openDocument(animation));
        content.addView(open,new LinearLayout.LayoutParams(-1,dp(50)));
        card.addView(content,new FrameLayout.LayoutParams(-1,-1)); return card;
    }

    private void openDocument(boolean animation){
        Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        intent.setType(animation?"*/*":"image/*");
        a.startActivityForResult(intent, animation?2002:2001);
    }

    public View createWorkspace(boolean animation, String source){
        if(!animation) return createDrawingWorkspace(source);

        LinearLayout workspace=col();
        workspace.setBackgroundColor(bg);
        workspace.setGravity(Gravity.CENTER);
        TextView title=txt("Entorno de Animación",28,text,true);
        title.setGravity(Gravity.CENTER);
        workspace.addView(title,new LinearLayout.LayoutParams(-1,dp(64)));
        String message=source==null
                ? "Preparado para integrar el núcleo de animación de Velyntora."
                : "Archivo seleccionado: "+source;
        TextView status=txt(message,15,muted,false);
        status.setGravity(Gravity.CENTER);
        workspace.addView(status,new LinearLayout.LayoutParams(-1,dp(48)));
        Button back=outline("Volver al inicio");
        back.setOnClickListener(v -> showHome());
        LinearLayout.LayoutParams bp=new LinearLayout.LayoutParams(dp(360),dp(52));
        bp.gravity=Gravity.CENTER_HORIZONTAL;
        workspace.addView(back,bp);
        return workspace;
    }

    private View createDrawingWorkspace(String source){
        LinearLayout root=col();
        root.setBackgroundColor(Color.rgb(20,22,27));

        // Barra superior: conserva la organización acordada para Velyntora.
        LinearLayout menu=row();
        menu.setGravity(Gravity.CENTER_VERTICAL);
        menu.setPadding(dp(8),0,dp(8),0);
        String[] menus={"Archivo","Editar","Ver","Imagen","Capa","Seleccionar","Filtro","Herramientas","Configuración","Ayuda"};
        for(String item:menus){
            TextView entry=txt(item,13,text,false);
            entry.setGravity(Gravity.CENTER);
            entry.setPadding(dp(10),0,dp(10),0);
            menu.addView(entry,new LinearLayout.LayoutParams(-2,-1));
        }
        Space menuSpace=new Space(a);
        menu.addView(menuSpace,new LinearLayout.LayoutParams(0,1,1));
        Button home=outline("Inicio");
        home.setOnClickListener(v -> showHome());
        menu.addView(home,new LinearLayout.LayoutParams(dp(92),dp(38)));
        root.addView(menu,new LinearLayout.LayoutParams(-1,dp(48)));

        LinearLayout body=row();

        // Herramientas: panel reservado en tres columnas, como se definió.
        LinearLayout tools=col();
        tools.setPadding(dp(8),dp(8),dp(8),dp(8));
        tools.setBackgroundColor(Color.rgb(26,29,36));
        TextView toolsTitle=txt("Herramientas",14,text,true);
        toolsTitle.setGravity(Gravity.CENTER);
        tools.addView(toolsTitle,new LinearLayout.LayoutParams(-1,dp(36)));
        GridLayout toolGrid=new GridLayout(a);
        toolGrid.setColumnCount(3);
        String[] toolNames={"Pincel","Borrador","Línea/Curva","Selección","Mover","Relleno","Texto","Formas","Color"};
        for(String tool:toolNames){
            Button b=outline(tool);
            b.setTextSize(10);
            toolGrid.addView(b,new GridLayout.LayoutParams(
                    GridLayout.spec(GridLayout.UNDEFINED,1f),
                    GridLayout.spec(GridLayout.UNDEFINED,1f)));
        }
        tools.addView(toolGrid,new LinearLayout.LayoutParams(-1,0,1));
        body.addView(tools,new LinearLayout.LayoutParams(dp(220),-1));

        // Centro: superficie de lienzo independiente del resto de paneles.
        FrameLayout canvasArea=new FrameLayout(a);
        canvasArea.setBackgroundColor(Color.rgb(42,45,52));
        TextView canvas=txt(source==null?"Lienzo":"Lienzo · "+source,15,Color.rgb(125,132,145),false);
        canvas.setGravity(Gravity.CENTER);
        GradientDrawable paper=round(Color.rgb(245,245,245),Color.rgb(82,88,99),4);
        canvas.setBackground(paper);
        FrameLayout.LayoutParams canvasParams=new FrameLayout.LayoutParams(dp(520),dp(340));
        canvasParams.gravity=Gravity.CENTER;
        canvasArea.addView(canvas,canvasParams);
        body.addView(canvasArea,new LinearLayout.LayoutParams(0,-1,1));

        // Panel derecho reservado para el sistema de capas del núcleo de Krita.
        LinearLayout layers=col();
        layers.setPadding(dp(10),dp(8),dp(10),dp(8));
        layers.setBackgroundColor(Color.rgb(26,29,36));
        TextView layersTitle=txt("Capas",15,text,true);
        layers.addView(layersTitle,new LinearLayout.LayoutParams(-1,dp(38)));
        TextView layer=txt("▣  Capa 1",13,text,false);
        layer.setGravity(Gravity.CENTER_VERTICAL);
        layer.setPadding(dp(10),0,0,0);
        layer.setBackground(round(Color.rgb(42,46,56),Color.TRANSPARENT,6));
        layers.addView(layer,new LinearLayout.LayoutParams(-1,dp(46)));
        body.addView(layers,new LinearLayout.LayoutParams(dp(210),-1));

        root.addView(body,new LinearLayout.LayoutParams(-1,0,1));

        // Paleta inferior estilo Pinta: estructura primero; motor de color después.
        LinearLayout palette=row();
        palette.setGravity(Gravity.CENTER_VERTICAL);
        palette.setPadding(dp(12),0,dp(12),0);
        palette.setBackgroundColor(Color.rgb(24,27,33));
        TextView paletteTitle=txt("Colores",13,text,true);
        palette.addView(paletteTitle,new LinearLayout.LayoutParams(dp(70),-1));
        int[] colors={Color.BLACK,Color.DKGRAY,Color.GRAY,Color.WHITE,Color.RED,Color.YELLOW,Color.GREEN,Color.CYAN,Color.BLUE,Color.MAGENTA};
        for(int c:colors){
            TextView swatch=new TextView(a);
            swatch.setBackground(round(c,Color.rgb(95,100,110),5));
            LinearLayout.LayoutParams cp=new LinearLayout.LayoutParams(dp(32),dp(32));
            cp.setMargins(dp(4),0,dp(4),0);
            palette.addView(swatch,cp);
        }
        Space paletteSpace=new Space(a);
        palette.addView(paletteSpace,new LinearLayout.LayoutParams(0,1,1));
        palette.addView(outline("+ Guardar color"),new LinearLayout.LayoutParams(dp(130),dp(38)));
        root.addView(palette,new LinearLayout.LayoutParams(-1,dp(54)));

        return root;
    }

    private void openWorkspace(boolean animation){
        if(a instanceof MainActivity) ((MainActivity)a).showWorkspace(animation,null);
        else a.setContentView(createWorkspace(animation,null));
    }

    private void showInfo(String page){
        if(a instanceof MainActivity) ((MainActivity)a).showInfo(page);
        else a.setContentView(createInfoPage(page));
    }

    private void showHome(){
        if(a instanceof MainActivity) ((MainActivity)a).showHome();
        else a.setContentView(create());
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
