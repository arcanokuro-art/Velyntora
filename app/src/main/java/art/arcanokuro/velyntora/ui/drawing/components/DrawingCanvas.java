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
        private float lastX,lastY;

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
        }

        @Override public boolean onTouchEvent(MotionEvent event){
            if(!supportsFreehand())return false;
            float x=event.getX(),y=event.getY();
            configurePaint();
            switch(event.getActionMasked()){
                case MotionEvent.ACTION_DOWN:
                    path.reset();path.moveTo(x,y);lastX=x;lastY=y;invalidate();return true;
                case MotionEvent.ACTION_MOVE:
                    float midX=(x+lastX)/2f,midY=(y+lastY)/2f;
                    path.quadTo(lastX,lastY,midX,midY);lastX=x;lastY=y;invalidate();return true;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    path.lineTo(x,y);
                    if(bitmapCanvas!=null)bitmapCanvas.drawPath(path,paint);
                    path.reset();invalidate();return true;
                default:return false;
            }
        }

        private boolean supportsFreehand(){
            return "Pincel".equals(state.tool())||"Borrador".equals(state.tool());
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
