package com.example.liquidglass;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.text.TextPaint;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;

import androidx.annotation.Nullable;

/**
 * Custom Settings Slider View matching the Liquid Glass settings in Nexagram:
 * Displays title on the top-left, numerical value (e.g. "360°" or "150%") on the right,
 * and an interactive fluid track + thumb slider.
 */
public class LiquidGlassSeekBarView extends View {

    public enum Type {
        ANGLE,      // Range: 0° to 360°
        INTENSITY   // Range: 0% to 150%
    }

    private Type type = Type.ANGLE;
    private int currentValue = 0;

    private final TextPaint titlePaint = new TextPaint(Paint.ANTI_ALIAS_FLAG);
    private final TextPaint valuePaint = new TextPaint(Paint.ANTI_ALIAS_FLAG);
    private final Paint trackBackgroundPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint trackProgressPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint thumbPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint thumbStrokePaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    private final RectF trackRect = new RectF();
    private boolean isDragging = false;

    public interface OnValueChangeListener {
        void onValueChanged(LiquidGlassSeekBarView view, int value);
    }

    private OnValueChangeListener listener;

    public LiquidGlassSeekBarView(Context context) {
        this(context, null);
    }

    public LiquidGlassSeekBarView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        float density = getResources().getDisplayMetrics().density;

        titlePaint.setTextSize(14f * density);
        titlePaint.setColor(0xFFFFFFFF); // White text

        valuePaint.setTextSize(14f * density);
        valuePaint.setColor(0xFF4FAAFF); // Light blue accent text
        valuePaint.setTextAlign(Paint.Align.RIGHT);

        trackBackgroundPaint.setColor(0x33FFFFFF); // Translucent gray background track
        trackBackgroundPaint.setStyle(Paint.Style.FILL);

        trackProgressPaint.setColor(0xFF2688EB); // Blue active track
        trackProgressPaint.setStyle(Paint.Style.FILL);

        thumbPaint.setColor(0xFFFFFFFF); // Solid white thumb
        thumbPaint.setStyle(Paint.Style.FILL);

        thumbStrokePaint.setColor(0x80FFFFFF);
        thumbStrokePaint.setStyle(Paint.Style.STROKE);
        thumbStrokePaint.setStrokeWidth(1.2f * density);
    }

    public void setType(Type type) {
        this.type = type;
        if (type == Type.ANGLE) {
            currentValue = LiquidGlassConfig.get(getContext()).getAngle();
        } else {
            currentValue = LiquidGlassConfig.get(getContext()).getIntensity();
        }
        invalidate();
    }

    public void setOnValueChangeListener(OnValueChangeListener listener) {
        this.listener = listener;
    }

    public int getValue() {
        return currentValue;
    }

    public void setValue(int value) {
        int max = (type == Type.ANGLE) ? LiquidGlassConfig.MAX_ANGLE : LiquidGlassConfig.MAX_INTENSITY;
        this.currentValue = Math.max(0, Math.min(max, value));
        invalidate();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        float density = getResources().getDisplayMetrics().density;
        int desiredHeight = (int) (64f * density);
        int width = MeasureSpec.getSize(widthMeasureSpec);
        setMeasuredDimension(width, resolveSize(desiredHeight, heightMeasureSpec));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float density = getResources().getDisplayMetrics().density;
        float w = getWidth();
        float h = getHeight();

        // 1. Draw Title Text
        String title = (type == Type.ANGLE) ? "Liquid Glass angle" : "Liquid Glass intensity";
        canvas.drawText(title, 16f * density, 22f * density, titlePaint);

        // 2. Draw Value Text (e.g. "360°" or "150%")
        String valueStr = (type == Type.ANGLE) ? currentValue + "°" : currentValue + "%";
        canvas.drawText(valueStr, w - 16f * density, 22f * density, valuePaint);

        // 3. Track Dimensions
        float trackLeft = 16f * density;
        float trackRight = w - 16f * density;
        float trackY = 44f * density;
        float trackHeight = 5f * density;
        float trackRadius = trackHeight / 2.0f;

        // Draw Inactive Background Track
        trackRect.set(trackLeft, trackY - trackHeight / 2f, trackRight, trackY + trackHeight / 2f);
        canvas.drawRoundRect(trackRect, trackRadius, trackRadius, trackBackgroundPaint);

        // 4. Progress and Thumb Position
        int max = (type == Type.ANGLE) ? LiquidGlassConfig.MAX_ANGLE : LiquidGlassConfig.MAX_INTENSITY;
        float progressFraction = (float) currentValue / (float) max;
        float thumbX = trackLeft + progressFraction * (trackRight - trackLeft);

        // Draw Active Progress Track
        trackRect.set(trackLeft, trackY - trackHeight / 2f, thumbX, trackY + trackHeight / 2f);
        canvas.drawRoundRect(trackRect, trackRadius, trackRadius, trackProgressPaint);

        // 5. Draw Capsule Pill Thumb
        float thumbW = (isDragging ? 32f : 24f) * density;
        float thumbH = 16f * density;
        float thumbR = thumbH / 2.0f;

        RectF thumbRect = new RectF(thumbX - thumbW / 2f, trackY - thumbH / 2f, thumbX + thumbW / 2f, trackY + thumbH / 2f);
        canvas.drawRoundRect(thumbRect, thumbR, thumbR, thumbPaint);
        canvas.drawRoundRect(thumbRect, thumbR, thumbR, thumbStrokePaint);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        float density = getResources().getDisplayMetrics().density;
        float trackLeft = 16f * density;
        float trackRight = getWidth() - 16f * density;

        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_MOVE:
                isDragging = true;
                getParent().requestDisallowInterceptTouchEvent(true);
                float x = Math.max(trackLeft, Math.min(trackRight, event.getX()));
                float fraction = (x - trackLeft) / (trackRight - trackLeft);
                int max = (type == Type.ANGLE) ? LiquidGlassConfig.MAX_ANGLE : LiquidGlassConfig.MAX_INTENSITY;
                currentValue = Math.round(fraction * max);

                // Update config
                if (type == Type.ANGLE) {
                    LiquidGlassConfig.get(getContext()).setAngle(currentValue);
                } else {
                    LiquidGlassConfig.get(getContext()).setIntensity(currentValue);
                }

                if (listener != null) {
                    listener.onValueChanged(this, currentValue);
                }
                invalidate();
                return true;

            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                isDragging = false;
                invalidate();
                return true;
        }
        return super.onTouchEvent(event);
    }
}
