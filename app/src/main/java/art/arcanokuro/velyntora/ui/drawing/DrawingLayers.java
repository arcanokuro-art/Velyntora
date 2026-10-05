package art.arcanokuro.velyntora.ui.drawing;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class DrawingLayers {
    public static final class Layer {
        private final String name;
        private Bitmap bitmap;
        private boolean visible=true;
        Layer(String n,Bitmap b){name=n;bitmap=b;}
        public String name(){return name;}
        public Bitmap bitmap(){return bitmap;}
        public boolean visible(){return visible;}
        public void setVisible(boolean value){visible=value;}
        public void setBitmap(Bitmap value){bitmap=value;}
    }

    private final List<Layer> layers=new ArrayList<>();
    private int active=0;

    public DrawingLayers(int width,int height){
        layers.add(new Layer("Capa 1",Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888)));
    }

    public List<Layer> all(){return Collections.unmodifiableList(layers);}
    public Layer active(){return layers.get(active);}
    public int activeIndex(){return active;}
    public void setActive(int index){if(index>=0&&index<layers.size())active=index;}

    public Layer add(int width,int height){
        Layer layer=new Layer("Capa "+(layers.size()+1),Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888));
        layers.add(layer);active=layers.size()-1;return layer;
    }

    public boolean removeActive(){
        if(layers.size()<=1)return false;
        Layer removed=layers.remove(active);
        if(removed.bitmap()!=null&&!removed.bitmap().isRecycled())removed.bitmap().recycle();
        active=Math.min(active,layers.size()-1);return true;
    }

    public Bitmap composite(int width,int height){
        Bitmap result=Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888);
        Canvas canvas=new Canvas(result);
        for(Layer layer:layers)if(layer.visible()&&layer.bitmap()!=null)canvas.drawBitmap(layer.bitmap(),0,0,null);
        return result;
    }
}
