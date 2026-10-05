package art.arcanokuro.velyntora.ui.drawing;

import java.util.ArrayList;
import java.util.List;

public final class DrawingState {
    public interface Listener { void onDrawingStateChanged(DrawingState state); }

    private String tool="Pincel";
    private int brushSize=40;
    private int opacity=100;
    private int color=0xff000000;
    private int zoom=100;
    private final List<Listener> listeners=new ArrayList<>();

    public void addListener(Listener value){if(value!=null&&!listeners.contains(value))listeners.add(value);}
    public void removeListener(Listener value){listeners.remove(value);}
    public String tool(){return tool;}
    public int brushSize(){return brushSize;}
    public int opacity(){return opacity;}
    public int color(){return color;}
    public int zoom(){return zoom;}

    public void setTool(String value){tool=value;changed();}
    public void setBrushSize(int value){brushSize=Math.max(1,Math.min(200,value));changed();}
    public void setOpacity(int value){opacity=Math.max(0,Math.min(100,value));changed();}
    public void setColor(int value){color=value;changed();}
    public void setZoom(int value){zoom=Math.max(10,Math.min(400,value));changed();}

    private void changed(){
        for(Listener listener:new ArrayList<>(listeners)) listener.onDrawingStateChanged(this);
    }
}
