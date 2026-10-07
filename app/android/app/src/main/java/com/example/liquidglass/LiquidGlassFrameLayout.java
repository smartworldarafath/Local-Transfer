package com.example.liquidglass;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.os.Build;
import android.util.AttributeSet;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import org.localsend.localsend_app.R;

/**
 * Drop-in FrameLayout that applies real-time Snell's Law Liquid Glass refraction
 * to its background and bounds on Android 13+ (API 33+).
 * Automatically reacts to LiquidGlassConfig changes (Angle & Intensity).
 */
public class LiquidGlassFrameLayout extends FrameLayout implements LiquidGlassConfig.OnConfigChangeListener {

    private LiquidGlassEffect liquidGlassEffect;
    private float cornerRadiusDp = 18.0f;
    private int glassTintColor = Color.argb(30, 255, 255, 255); // Frosted white translucent tint

    public LiquidGlassFrameLayout(@NonNull Context context) {
        this(context, null);
    }

    public LiquidGlassFrameLayout(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public LiquidGlassFrameLayout(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        setWillNotDraw(false);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                // Initialize effect with raw resource or embedded shader
                liquidGlassEffect = LiquidGlassEffect.fromRawResource(getContext(), R.raw.liquid_glass_shader);
            } catch (Exception ignored) {
                // In standalone usage, users can pass shader code directly
            }
        }
    }

    public void setShaderCode(String shaderSource) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            this.liquidGlassEffect = new LiquidGlassEffect(shaderSource);
            applyGlassEffect();
        }
    }

    public void setCornerRadiusDp(float radiusDp) {
        this.cornerRadiusDp = radiusDp;
        applyGlassEffect();
    }

    public void setGlassTintColor(int color) {
        this.glassTintColor = color;
        applyGlassEffect();
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        LiquidGlassConfig.get(getContext()).addListener(this);
        applyGlassEffect();
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        LiquidGlassConfig.get(getContext()).removeListener(this);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        applyGlassEffect();
    }

    @Override
    public void onConfigChanged(int angleDegrees, int intensityPercent) {
        applyGlassEffect();
        postInvalidate();
    }

    private void applyGlassEffect() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && liquidGlassEffect != null) {
            if (getWidth() > 0 && getHeight() > 0) {
                float density = getResources().getDisplayMetrics().density;
                float radiusPx = cornerRadiusDp * density;
                LiquidGlassConfig config = LiquidGlassConfig.get(getContext());

                liquidGlassEffect.applyToView(
                        this,
                        radiusPx,
                        glassTintColor,
                        config.getAngle(),
                        config.getIntensity()
                );
            }
        }
    }
}
