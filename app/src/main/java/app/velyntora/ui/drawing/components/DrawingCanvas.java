package app.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.view.MotionEvent;
import android.net.Uri;
import java.io.InputStream;
import java.io.OutputStream;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.EditText;
import android.app.AlertDialog;

import app.velyntora.ui.drawing.DrawingState;
import app.velyntora.ui.drawing.DrawingLayers;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.ArrayList;
import java.util.List;

public final class DrawingCanvas implements DrawingState.Listener {
    private final Activity a;
    private final DrawingState state;
    private FrameLayout area;
    private PaintSurface surface;
    private DrawingLayers layers;
    private float panX=0f,panY=0f,panStartX,panStartY,viewStartX,viewStartY;
    private String lastTool;

    public DrawingCanvas(Activity activity,DrawingState drawingState){a=activity;state=drawingState;lastTool=drawingState.tool();}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(String documentName,String sourceUri){
        area=new FrameLayout(a);
        area.setBackgroundColor(Color.rgb(92,92,92));
        surface=new PaintSurface(sourceUri);
        FrameLayout.LayoutParams params=new FrameLayout.LayoutParams(dp(620),dp(430),android.view.Gravity.CENTER);
        area.addView(surface,params);
        updateTransform();
        return area;
    }

    @Override public void onDrawingStateChanged(DrawingState ignored){
        String tool=state.tool();
        if(surface!=null&&lastTool!=null&&!lastTool.equals(tool))surface.onToolChanged(lastTool,tool);
        lastTool=tool;updateTransform();if(surface!=null)surface.invalidate();
    }

    public void undo(){if(surface!=null)surface.undo();}
    public void redo(){if(surface!=null)surface.redo();}
    public int layerCount(){return layers==null?0:layers.all().size();}
    public int activeLayer(){return layers==null?0:layers.activeIndex();}
    public void addLayer(){if(surface!=null)surface.addLayer();}
    public void removeLayer(){if(surface!=null)surface.removeLayer();}
    public void nextLayer(){if(surface!=null)surface.nextLayer();}
    public void toggleLayerVisibility(){if(surface!=null)surface.toggleLayerVisibility();}
    public void clearActiveLayer(){if(surface!=null)surface.clearActiveLayer();}

    public boolean exportPng(Uri destination){
        if(surface==null||surface.bitmap==null||destination==null)return false;
        try(OutputStream out=a.getContentResolver().openOutputStream(destination)){
            Bitmap output=surface.composite();boolean ok=out!=null&&output.compress(Bitmap.CompressFormat.PNG,100,out);if(output!=surface.bitmap)output.recycle();return ok;
        }catch(Exception ignored){return false;}
    }

    private void updateTransform(){
        if(surface==null)return;
        float scale=state.zoom()/100f;
        surface.setScaleX(scale);surface.setScaleY(scale);
        surface.setTranslationX(panX);surface.setTranslationY(panY);
    }

    private final class PaintSurface extends View {
        private Bitmap bitmap;
        private Canvas bitmapCanvas;
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path=new Path();
        private float lastX,lastY,startX=-1f,startY=-1f,currentX,currentY;
        private float lineStartX=-1f,lineStartY=-1f,lineEndX=-1f,lineEndY=-1f,controlX,controlY;
        private boolean curvePending=false,curving=false;
        private Bitmap curveBase;
        private Bitmap transformBase;
        private Bitmap selectionBase,selectionPixels;
        private RectF selectionRect,selectionOrigin;
        private final List<float[]> polygonPoints=new ArrayList<>();
        private float transformStartX,transformStartY;
        private final Deque<Bitmap> undoStack=new ArrayDeque<>();
        private final Deque<Bitmap> redoStack=new ArrayDeque<>();

        private final String sourceUri;
        private boolean sourceLoaded=false;

        PaintSurface(String uri){
            super(a);sourceUri=uri;
            setBackgroundColor(Color.WHITE);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeCap(Paint.Cap.ROUND);
            paint.setStrokeJoin(Paint.Join.ROUND);
            setLayerType(View.LAYER_TYPE_HARDWARE,null);
        }

        @Override protected void onSizeChanged(int w,int h,int oldw,int oldh){
            if(w<=0||h<=0)return;
            if(layers==null){
                layers=new DrawingLayers(w,h);
                Bitmap initial=layers.active().bitmap();
                if(bitmap!=null){
                    new Canvas(initial).drawBitmap(bitmap,0,0,null);
                    if(!bitmap.isRecycled())bitmap.recycle();
                }else new Canvas(initial).drawColor(Color.TRANSPARENT,PorterDuff.Mode.CLEAR);
            }else layers.resize(w,h);
            bitmap=layers.active().bitmap();
            bitmapCanvas=new Canvas(bitmap);
            if(oldw>0&&oldh>0&&(oldw!=w||oldh!=h)){clearBitmapStack(undoStack);clearBitmapStack(redoStack);clearTransientDrawingState();}
            if(!sourceLoaded&&sourceUri!=null){loadSourceImage(w,h);sourceLoaded=true;layers.active().setBitmap(bitmap);}
        }

        private void loadSourceImage(int maxW,int maxH){
            Uri uri=Uri.parse(sourceUri);
            BitmapFactory.Options bounds=new BitmapFactory.Options();bounds.inJustDecodeBounds=true;
            try(InputStream in=a.getContentResolver().openInputStream(uri)){BitmapFactory.decodeStream(in,null,bounds);}catch(Exception ignored){return;}
            if(bounds.outWidth<=0||bounds.outHeight<=0)return;
            int sample=1;
            while(bounds.outWidth/sample>maxW*2||bounds.outHeight/sample>maxH*2)sample*=2;
            BitmapFactory.Options options=new BitmapFactory.Options();options.inSampleSize=Math.max(1,sample);options.inPreferredConfig=Bitmap.Config.ARGB_8888;
            try(InputStream in=a.getContentResolver().openInputStream(uri)){
                Bitmap source=BitmapFactory.decodeStream(in,null,options);if(source==null)return;
                float scale=Math.min((float)maxW/source.getWidth(),(float)maxH/source.getHeight());scale=Math.min(1f,scale);
                int w=Math.max(1,Math.round(source.getWidth()*scale)),h=Math.max(1,Math.round(source.getHeight()*scale));
                Bitmap fitted=scale<1f?Bitmap.createScaledBitmap(source,w,h,true):source;
                bitmapCanvas.drawColor(Color.TRANSPARENT,PorterDuff.Mode.CLEAR);float left=(maxW-w)/2f,top=(maxH-h)/2f;bitmapCanvas.drawBitmap(fitted,left,top,null);
                if(fitted!=source)fitted.recycle();source.recycle();clearBitmapStack(undoStack);clearBitmapStack(redoStack);
            }catch(Exception ignored){}
        }

        @Override protected void onDraw(Canvas canvas){
            super.onDraw(canvas);
            if(bitmap!=null){if(layers==null)canvas.drawBitmap(bitmap,0,0,null);else for(DrawingLayers.Layer layer:layers.all())if(layer.visible()&&layer.bitmap()!=null)canvas.drawBitmap(layer.bitmap(),0,0,null);}
            canvas.drawPath(path,paint);
            if("Línea/Curva".equals(state.tool())){
                configurePaint();
                if(curving){
                    Path preview=new Path();preview.moveTo(lineStartX,lineStartY);preview.quadTo(controlX,controlY,lineEndX,lineEndY);canvas.drawPath(preview,paint);
                }else if(startX>=0) canvas.drawLine(startX,startY,currentX,currentY,paint);
            }else if(isShapeTool()&&startX>=0){
                configurePaint();drawShape(canvas,startX,startY,currentX,currentY);
            }
            if(selectionRect!=null){Paint sel=new Paint(Paint.ANTI_ALIAS_FLAG);sel.setStyle(Paint.Style.STROKE);sel.setStrokeWidth(dp(1));sel.setColor(Color.rgb(40,140,255));sel.setPathEffect(new android.graphics.DashPathEffect(new float[]{dp(6),dp(4)},0));canvas.drawRect(selectionRect,sel);}
            if(!polygonPoints.isEmpty()){configurePaint();Path poly=new Path();float[] first=polygonPoints.get(0);poly.moveTo(first[0],first[1]);for(int i=1;i<polygonPoints.size();i++){float[] p=polygonPoints.get(i);poly.lineTo(p[0],p[1]);}canvas.drawPath(poly,paint);}
        }

        void onToolChanged(String previous,String current){
            if(!"Polígono".equals(current))polygonPoints.clear();
            boolean keepSelection="Mover".equals(current)&&("Seleccionar".equals(previous)||"Selección rectangular".equals(previous));
            if(!"Seleccionar".equals(current)&&!"Selección rectangular".equals(current)&&!"Mover".equals(current)&&!keepSelection)selectionRect=null;
            if(!"Línea/Curva".equals(current)){
                curvePending=false;curving=false;lineStartX=-1f;startX=startY=-1f;path.reset();
                if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=null;
            }
            invalidate();
        }

        @Override public boolean onTouchEvent(MotionEvent event){
            if("Mano".equals(state.tool()))return handlePan(event);
            if("Zoom".equals(state.tool()))return handleZoom(event);
            if(layers!=null&&!layers.active().visible()){
                if("Selección rectangular".equals(state.tool())||"Seleccionar".equals(state.tool()))return handleSelection(event);
                return true;
            }
            if("Texto".equals(state.tool()))return handleText(event);
            if("Selección rectangular".equals(state.tool())||"Seleccionar".equals(state.tool()))return handleSelection(event);
            if("Polígono".equals(state.tool()))return handlePolygon(event);
            if("Mover".equals(state.tool()))return handleMoveContent(event);
            if("Transformar".equals(state.tool()))return handleTransformContent(event);
            if(!supportsDrawingTool())return false;
            float x=event.getX(),y=event.getY();
            state.setPointer(Math.round(x),Math.round(y));
            configurePaint();
            switch(event.getActionMasked()){
                case MotionEvent.ACTION_DOWN:
                    if("Relleno".equals(state.tool())){
                        int fillAlpha=Math.round(255*(state.opacity()/100f));
                        int fillColor=(state.color()&0x00FFFFFF)|(fillAlpha<<24);
                        int fillX=Math.round(x),fillY=Math.round(y);
                        if(fillX<0||fillY<0||fillX>=bitmap.getWidth()||fillY>=bitmap.getHeight()||bitmap.getPixel(fillX,fillY)==fillColor)return true;
                        saveUndoSnapshot();clearBitmapStack(redoStack);
                        floodFill(fillX,fillY,fillColor);invalidate();return true;
                    }
                    if("Línea/Curva".equals(state.tool())&&curvePending){
                        saveUndoSnapshot();clearBitmapStack(redoStack);curving=true;controlX=x;controlY=y;invalidate();return true;
                    }
                    saveUndoSnapshot();clearBitmapStack(redoStack);
                    startX=currentX=x;startY=currentY=y;
                    path.reset();path.moveTo(x,y);lastX=x;lastY=y;invalidate();return true;
                case MotionEvent.ACTION_MOVE:
                    currentX=x;currentY=y;
                    if(curving){controlX=x;controlY=y;invalidate();return true;}
                    if(isShapeTool()){invalidate();return true;}
                    if(!"Línea/Curva".equals(state.tool())){
                        float midX=(x+lastX)/2f,midY=(y+lastY)/2f;
                        path.quadTo(lastX,lastY,midX,midY);lastX=x;lastY=y;
                    }
                    invalidate();return true;
                case MotionEvent.ACTION_CANCEL:
                    startX=startY=-1f;path.reset();curving=false;
                    if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=null;
                    lineStartX=lineStartY=lineEndX=lineEndY=-1f;curvePending=false;
                    discardLatestUndoSnapshot();invalidate();return true;
                case MotionEvent.ACTION_UP:
                    currentX=x;currentY=y;
                    if(bitmapCanvas!=null){
                        if(curving){
                            controlX=x;controlY=y;
                            if(curveBase!=null){bitmap=curveBase.copy(Bitmap.Config.ARGB_8888,true);bitmapCanvas=new Canvas(bitmap);if(layers!=null)layers.active().setBitmap(bitmap);}
                            Path curve=new Path();curve.moveTo(lineStartX,lineStartY);curve.quadTo(controlX,controlY,lineEndX,lineEndY);bitmapCanvas.drawPath(curve,paint);
                            curving=false;curvePending=false;if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=null;lineStartX=-1f;
                        }else if(isShapeTool()){
                            drawShape(bitmapCanvas,startX,startY,currentX,currentY);curvePending=false;if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=null;
                        }else if("Línea/Curva".equals(state.tool())){
                            lineStartX=startX;lineStartY=startY;lineEndX=currentX;lineEndY=currentY;
                            if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=bitmap.copy(Bitmap.Config.ARGB_8888,true);
                            bitmapCanvas.drawLine(lineStartX,lineStartY,lineEndX,lineEndY,paint);curvePending=true;
                        }else {path.lineTo(x,y);bitmapCanvas.drawPath(path,paint);curvePending=false;if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=null;}
                    }
                    startX=startY=-1f;path.reset();invalidate();return true;
                default:return false;
            }
        }

        private boolean handlePan(MotionEvent e){
            switch(e.getActionMasked()){
                case MotionEvent.ACTION_DOWN: panStartX=e.getRawX();panStartY=e.getRawY();viewStartX=panX;viewStartY=panY;return true;
                case MotionEvent.ACTION_MOVE: panX=viewStartX+(e.getRawX()-panStartX);panY=viewStartY+(e.getRawY()-panStartY);updateTransform();return true;
                case MotionEvent.ACTION_UP:case MotionEvent.ACTION_CANCEL:return true;default:return false;
            }
        }

        private boolean handleZoom(MotionEvent e){
            if(e.getActionMasked()==MotionEvent.ACTION_DOWN){int next=state.zoom()>=400?100:Math.min(400,state.zoom()+25);state.setZoom(next);return true;}
            return e.getActionMasked()==MotionEvent.ACTION_UP;
        }

        private boolean handleText(MotionEvent e){
            if(e.getActionMasked()!=MotionEvent.ACTION_DOWN)return true;final float x=e.getX(),y=e.getY();state.setPointer(Math.round(x),Math.round(y));
            EditText input=new EditText(a);input.setSingleLine(false);input.setHint("Texto");
            new AlertDialog.Builder(a).setTitle("Agregar texto").setView(input).setNegativeButton("Cancelar",null).setPositiveButton("Insertar",(d,w)->{
                String value=input.getText().toString();if(value.trim().isEmpty()||bitmapCanvas==null)return;saveUndoSnapshot();clearBitmapStack(redoStack);
                Paint tp=new Paint(Paint.ANTI_ALIAS_FLAG);tp.setColor(state.color());tp.setAlpha(Math.round(255*(state.opacity()/100f)));tp.setTextSize(dp(Math.max(12,state.brushSize()*2)));float yy=y;
                for(String line:value.split("\\n",-1)){bitmapCanvas.drawText(line,x,yy,tp);yy+=tp.getTextSize()*1.2f;}invalidate();
            }).show();return true;
        }

        private boolean handleSelection(MotionEvent e){
            float x=e.getX(),y=e.getY();state.setPointer(Math.round(x),Math.round(y));
            switch(e.getActionMasked()){
                case MotionEvent.ACTION_DOWN:startX=x;startY=y;selectionRect=new RectF(x,y,x,y);invalidate();return true;
                case MotionEvent.ACTION_MOVE:case MotionEvent.ACTION_UP:selectionRect.set(Math.min(startX,x),Math.min(startY,y),Math.max(startX,x),Math.max(startY,y));invalidate();if(e.getActionMasked()==MotionEvent.ACTION_UP){startX=startY=-1f;}return true;
                case MotionEvent.ACTION_CANCEL:startX=startY=-1f;selectionRect=null;invalidate();return true;default:return false;
            }
        }

        private boolean handlePolygon(MotionEvent e){
            if(e.getActionMasked()!=MotionEvent.ACTION_DOWN)return true;float x=e.getX(),y=e.getY();state.setPointer(Math.round(x),Math.round(y));
            if(!polygonPoints.isEmpty()){float[] first=polygonPoints.get(0);float dx=x-first[0],dy=y-first[1];if(polygonPoints.size()>=3&&dx*dx+dy*dy<=dp(18)*dp(18)){
                saveUndoSnapshot();clearBitmapStack(redoStack);configurePaint();Path poly=new Path();poly.moveTo(first[0],first[1]);for(int i=1;i<polygonPoints.size();i++){float[] p=polygonPoints.get(i);poly.lineTo(p[0],p[1]);}poly.close();bitmapCanvas.drawPath(poly,paint);polygonPoints.clear();invalidate();return true;}}
            polygonPoints.add(new float[]{x,y});invalidate();return true;
        }

        private boolean handleMoveContent(MotionEvent e){
            if(bitmap==null)return false;
            switch(e.getActionMasked()){
                case MotionEvent.ACTION_DOWN:
                    saveUndoSnapshot();transformStartX=e.getX();transformStartY=e.getY();
                    if(selectionRect!=null&&selectionRect.width()>1&&selectionRect.height()>1){
                        int l=Math.max(0,(int)selectionRect.left),t=Math.max(0,(int)selectionRect.top),r=Math.min(bitmap.getWidth(),(int)selectionRect.right),b=Math.min(bitmap.getHeight(),(int)selectionRect.bottom);
                        if(r>l&&b>t){selectionBase=bitmap.copy(Bitmap.Config.ARGB_8888,true);selectionPixels=Bitmap.createBitmap(bitmap,l,t,r-l,b-t);selectionOrigin=new RectF(l,t,r,b);}
                    }
                    if(selectionPixels==null)transformBase=bitmap.copy(Bitmap.Config.ARGB_8888,true);return true;
                case MotionEvent.ACTION_MOVE:case MotionEvent.ACTION_UP:
                    float dx=e.getX()-transformStartX,dy=e.getY()-transformStartY;
                    if(selectionPixels!=null&&selectionBase!=null){
                        bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);bitmapCanvas.drawBitmap(selectionBase,0,0,null);
                        Paint clear=new Paint();clear.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));clear.setStyle(Paint.Style.FILL);bitmapCanvas.drawRect(selectionOrigin,clear);
                        bitmapCanvas.drawBitmap(selectionPixels,selectionOrigin.left+dx,selectionOrigin.top+dy,null);
                        selectionRect=new RectF(selectionOrigin);selectionRect.offset(dx,dy);
                    }else if(transformBase!=null){bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);bitmapCanvas.drawBitmap(transformBase,dx,dy,null);}
                    invalidate();
                    if(e.getActionMasked()==MotionEvent.ACTION_UP){
                        boolean changed=Math.abs(dx)>0.001f||Math.abs(dy)>0.001f;
                        if(changed)clearBitmapStack(redoStack);else discardLatestUndoSnapshot();
                        if(transformBase!=null)transformBase.recycle();transformBase=null;if(selectionBase!=null)selectionBase.recycle();selectionBase=null;if(selectionPixels!=null)selectionPixels.recycle();selectionPixels=null;selectionOrigin=null;
                    }return true;
                case MotionEvent.ACTION_CANCEL:
                    if(selectionBase!=null){
                        bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);bitmapCanvas.drawBitmap(selectionBase,0,0,null);
                        if(selectionOrigin!=null)selectionRect=new RectF(selectionOrigin);
                    }else if(transformBase!=null){
                        bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);bitmapCanvas.drawBitmap(transformBase,0,0,null);
                    }
                    if(transformBase!=null&&!transformBase.isRecycled())transformBase.recycle();transformBase=null;
                    if(selectionBase!=null&&!selectionBase.isRecycled())selectionBase.recycle();selectionBase=null;
                    if(selectionPixels!=null&&!selectionPixels.isRecycled())selectionPixels.recycle();selectionPixels=null;
                    selectionOrigin=null;discardLatestUndoSnapshot();invalidate();return true;default:return false;
            }
        }

        private boolean handleTransformContent(MotionEvent e){
            if(bitmap==null)return false;
            switch(e.getActionMasked()){
                case MotionEvent.ACTION_DOWN:saveUndoSnapshot();transformBase=bitmap.copy(Bitmap.Config.ARGB_8888,true);transformStartX=e.getX();return true;
                case MotionEvent.ACTION_MOVE:case MotionEvent.ACTION_UP:
                    if(transformBase==null)return true;float factor=Math.max(0.1f,Math.min(3f,1f+(e.getX()-transformStartX)/Math.max(1f,getWidth())));
                    int nw=Math.max(1,Math.round(transformBase.getWidth()*factor)),nh=Math.max(1,Math.round(transformBase.getHeight()*factor));
                    float left=(getWidth()-nw)/2f,top=(getHeight()-nh)/2f;
                    RectF destination=new RectF(left,top,left+nw,top+nh);
                    bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);bitmapCanvas.drawBitmap(transformBase,null,destination,paint);invalidate();
                    if(e.getActionMasked()==MotionEvent.ACTION_UP){
                        boolean changed=nw!=transformBase.getWidth()||nh!=transformBase.getHeight();
                        if(changed)clearBitmapStack(redoStack);else discardLatestUndoSnapshot();
                        transformBase.recycle();transformBase=null;
                    }return true;
                case MotionEvent.ACTION_CANCEL:
                    if(transformBase!=null){
                        bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);bitmapCanvas.drawBitmap(transformBase,0,0,null);
                        if(!transformBase.isRecycled())transformBase.recycle();transformBase=null;
                    }
                    discardLatestUndoSnapshot();invalidate();
                    return true;default:return false;
            }
        }

        private void clearTransientDrawingState(){
            polygonPoints.clear();selectionRect=null;selectionOrigin=null;path.reset();
            startX=startY=-1f;lineStartX=lineStartY=lineEndX=lineEndY=-1f;curvePending=false;curving=false;
            if(curveBase!=null&&!curveBase.isRecycled())curveBase.recycle();curveBase=null;
            if(transformBase!=null&&!transformBase.isRecycled())transformBase.recycle();transformBase=null;
            if(selectionBase!=null&&!selectionBase.isRecycled())selectionBase.recycle();selectionBase=null;
            if(selectionPixels!=null&&!selectionPixels.isRecycled())selectionPixels.recycle();selectionPixels=null;
        }

        void clearActiveLayer(){
            if(bitmap==null||isBitmapTransparent(bitmap))return;
            saveUndoSnapshot();clearBitmapStack(redoStack);bitmap.eraseColor(Color.TRANSPARENT);bitmapCanvas=new Canvas(bitmap);invalidate();
        }

        private boolean isBitmapTransparent(Bitmap source){
            int w=source.getWidth(),h=source.getHeight();
            int[] row=new int[w];
            for(int y=0;y<h;y++){
                source.getPixels(row,0,w,0,y,w,1);
                for(int pixel:row)if((pixel>>>24)!=0)return false;
            }
            return true;
        }

        Bitmap composite(){return layers==null?bitmap:layers.composite(getWidth(),getHeight());}

        void addLayer(){if(layers==null)return;clearTransientDrawingState();layers.active().setBitmap(bitmap);layers.add(getWidth(),getHeight());bitmap=layers.active().bitmap();bitmapCanvas=new Canvas(bitmap);clearBitmapStack(undoStack);clearBitmapStack(redoStack);invalidate();}
        void removeLayer(){if(layers==null)return;clearTransientDrawingState();layers.active().setBitmap(bitmap);if(layers.removeActive()){bitmap=layers.active().bitmap();bitmapCanvas=new Canvas(bitmap);clearBitmapStack(undoStack);clearBitmapStack(redoStack);invalidate();}}
        void nextLayer(){if(layers==null||layers.all().isEmpty())return;clearTransientDrawingState();layers.active().setBitmap(bitmap);layers.setActive((layers.activeIndex()+1)%layers.all().size());bitmap=layers.active().bitmap();bitmapCanvas=new Canvas(bitmap);clearBitmapStack(undoStack);clearBitmapStack(redoStack);invalidate();}
        void toggleLayerVisibility(){if(layers==null)return;layers.active().setVisible(!layers.active().visible());invalidate();}

        void undo(){
            if(undoStack.isEmpty()||bitmap==null)return;
            Bitmap replaced=bitmap;
            redoStack.push(replaced.copy(Bitmap.Config.ARGB_8888,true));
            bitmap=undoStack.pop();bitmapCanvas=new Canvas(bitmap);
            if(layers!=null)layers.active().setBitmap(bitmap);
            if(replaced!=bitmap&&!replaced.isRecycled())replaced.recycle();
            invalidate();
        }

        void redo(){
            if(redoStack.isEmpty()||bitmap==null)return;
            Bitmap replaced=bitmap;
            undoStack.push(replaced.copy(Bitmap.Config.ARGB_8888,true));
            bitmap=redoStack.pop();bitmapCanvas=new Canvas(bitmap);
            if(layers!=null)layers.active().setBitmap(bitmap);
            if(replaced!=bitmap&&!replaced.isRecycled())replaced.recycle();
            invalidate();
        }

        private void discardLatestUndoSnapshot(){
            if(undoStack.isEmpty())return;
            Bitmap cancelled=undoStack.pop();
            if(cancelled!=null&&!cancelled.isRecycled())cancelled.recycle();
        }

        private void clearBitmapStack(Deque<Bitmap> stack){
            while(!stack.isEmpty()){Bitmap old=stack.pop();if(old!=null&&!old.isRecycled())old.recycle();}
        }

        private void saveUndoSnapshot(){
            if(bitmap==null)return;
            undoStack.push(bitmap.copy(Bitmap.Config.ARGB_8888,true));
            while(undoStack.size()>30){Bitmap old=undoStack.removeLast();if(old!=null&&!old.isRecycled())old.recycle();}
        }

        private boolean supportsDrawingTool(){
            return "Pincel".equals(state.tool())||"Borrador".equals(state.tool())||"Línea/Curva".equals(state.tool())||"Relleno".equals(state.tool())||isShapeTool();
        }

        private void floodFill(int sx,int sy,int replacement){
            if(bitmap==null||sx<0||sy<0||sx>=bitmap.getWidth()||sy>=bitmap.getHeight())return;
            int target=bitmap.getPixel(sx,sy);if(target==replacement)return;
            int w=bitmap.getWidth(),h=bitmap.getHeight();
            ArrayDeque<Integer> q=new ArrayDeque<>();q.add(sy*w+sx);
            while(!q.isEmpty()){
                int point=q.removeFirst(),x=point%w,y=point/w;
                if(bitmap.getPixel(x,y)!=target)continue;
                int left=x,right=x;
                while(left>0&&bitmap.getPixel(left-1,y)==target)left--;
                while(right+1<w&&bitmap.getPixel(right+1,y)==target)right++;
                boolean spanUp=false,spanDown=false;
                for(int px=left;px<=right;px++){
                    bitmap.setPixel(px,y,replacement);
                    if(y>0){
                        boolean match=bitmap.getPixel(px,y-1)==target;
                        if(match&&!spanUp)q.add((y-1)*w+px);
                        spanUp=match;
                    }
                    if(y+1<h){
                        boolean match=bitmap.getPixel(px,y+1)==target;
                        if(match&&!spanDown)q.add((y+1)*w+px);
                        spanDown=match;
                    }
                }
            }
        }

        private boolean isShapeTool(){return "Rectángulo".equals(state.tool())||"Elipse".equals(state.tool());}

        private void drawShape(Canvas target,float x1,float y1,float x2,float y2){
            RectF bounds=new RectF(Math.min(x1,x2),Math.min(y1,y2),Math.max(x1,x2),Math.max(y1,y2));
            if("Rectángulo".equals(state.tool()))target.drawRect(bounds,paint);else if("Elipse".equals(state.tool()))target.drawOval(bounds,paint);
        }

        private void configurePaint(){
            paint.setStrokeWidth(dp(state.brushSize()));
            if("Borrador".equals(state.tool())){
                paint.setColor(Color.TRANSPARENT);
                paint.setAlpha(255);
                paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
            }else{
                paint.setXfermode(null);
                paint.setColor(state.color());
                paint.setAlpha(Math.round(255*(state.opacity()/100f)));
            }
        }
    }
}
