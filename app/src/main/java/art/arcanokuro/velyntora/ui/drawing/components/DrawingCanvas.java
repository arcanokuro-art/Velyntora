package art.arcanokuro.velyntora.ui.drawing.components;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

import art.arcanokuro.velyntora.ui.drawing.DrawingState;

import java.util.ArrayDeque;
import java.util.Deque;

public final class DrawingCanvas implements DrawingState.Listener {
    private final Activity a;
    private final DrawingState state;
    private FrameLayout area;
    private PaintSurface surface;

    public DrawingCanvas(Activity activity,DrawingState drawingState){a=activity;state=drawingState;}
    private int dp(int v){return Math.round(v*a.getResources().getDisplayMetrics().density);}

    public View create(String documentName){
        area=new FrameLayout(a);
        area.setBackgroundColor(Color.rgb(92,92,92));
        surface=new PaintSurface();
        FrameLayout.LayoutParams params=new FrameLayout.LayoutParams(dp(620),dp(430),android.view.Gravity.CENTER);
        area.addView(surface,params);
        updateZoom();
        return area;
    }

    @Override public void onDrawingStateChanged(DrawingState ignored){updateZoom();if(surface!=null)surface.invalidate();}

    public void undo(){if(surface!=null)surface.undo();}
    public void redo(){if(surface!=null)surface.redo();}

    private void updateZoom(){
        if(surface==null)return;
        float scale=state.zoom()/100f;
        surface.setScaleX(scale);
        surface.setScaleY(scale);
    }

    private final class PaintSurface extends View {
        private Bitmap bitmap;
        private Canvas bitmapCanvas;
        private final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path=new Path();
        private float lastX,lastY,startX,startY,currentX,currentY;
        private final Deque<Bitmap> undoStack=new ArrayDeque<>();
        private final Deque<Bitmap> redoStack=new ArrayDeque<>();

        PaintSurface(){
            super(a);
            setBackgroundColor(Color.WHITE);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeCap(Paint.Cap.ROUND);
            paint.setStrokeJoin(Paint.Join.ROUND);
            setLayerType(View.LAYER_TYPE_HARDWARE,null);
        }

        @Override protected void onSizeChanged(int w,int h,int oldw,int oldh){
            if(w<=0||h<=0)return;
            Bitmap next=Bitmap.createBitmap(w,h,Bitmap.Config.ARGB_8888);
            Canvas nextCanvas=new Canvas(next);
            nextCanvas.drawColor(Color.WHITE);
            if(bitmap!=null)nextCanvas.drawBitmap(bitmap,0,0,null);
            bitmap=next;
            bitmapCanvas=nextCanvas;
        }

        @Override protected void onDraw(Canvas canvas){
            super.onDraw(canvas);
            if(bitmap!=null)canvas.drawBitmap(bitmap,0,0,null);
            canvas.drawPath(path,paint);
            if("Línea/Curva".equals(state.tool())&&startX>=0){
                configurePaint();
                canvas.drawLine(startX,startY,currentX,currentY,paint);
            }
        }

        @Override public boolean onTouchEvent(MotionEvent event){
            if(!supportsDrawingTool())return false;
            float x=event.getX(),y=event.getY();
            configurePaint();
            switch(event.getActionMasked()){
                case MotionEvent.ACTION_DOWN:
                    saveUndoSnapshot();
                    redoStack.clear();
                    startX=currentX=x;startY=currentY=y;
                    path.reset();path.moveTo(x,y);lastX=x;lastY=y;invalidate();return true;
                case MotionEvent.ACTION_MOVE:
                    currentX=x;currentY=y;
                    if(!"Línea/Curva".equals(state.tool())){
                        float midX=(x+lastX)/2f,midY=(y+lastY)/2f;
                        path.quadTo(lastX,lastY,midX,midY);lastX=x;lastY=y;
                    }
                    invalidate();return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    currentX=x;currentY=y;
                    if(bitmapCanvas!=null){
                        if("Línea/Curva".equals(state.tool())) bitmapCanvas.drawLine(startX,startY,currentX,currentY,paint);
                        else {path.lineTo(x,y);bitmapCanvas.drawPath(path,paint);}
                    }
                    startX=startY=-1f;path.reset();invalidate();return true;
                default:return false;
            }
        }

        void undo(){
            if(undoStack.isEmpty()||bitmap==null)return;
            redoStack.push(bitmap.copy(Bitmap.Config.ARGB_8888,true));
            bitmap=undoStack.pop();bitmapCanvas=new Canvas(bitmap);invalidate();
        }

        void redo(){
            if(redoStack.isEmpty()||bitmap==null)return;
            undoStack.push(bitmap.copy(Bitmap.Config.ARGB_8888,true));
            bitmap=redoStack.pop();bitmapCanvas=new Canvas(bitmap);invalidate();
        }

        private void saveUndoSnapshot(){
            if(bitmap==null)return;
            undoStack.push(bitmap.copy(Bitmap.Config.ARGB_8888,true));
            while(undoStack.size()>30)undoStack.removeLast();
        }

        private boolean supportsDrawingTool(){
            return "Pincel".equals(state.tool())||"Borrador".equals(state.tool())||"Línea/Curva".equals(state.tool());
        }

        private void configurePaint(){
            paint.setStrokeWidth(dp(state.brushSize()));
            if("Borrador".equals(state.tool())){
                paint.setColor(Color.WHITE);
                paint.setAlpha(255);
            }else{
                paint.setColor(state.color());
                paint.setAlpha(Math.round(255*(state.opacity()/100f)));
            }
        }
    }
}
