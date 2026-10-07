package com.example.liquidglass;

import android.content.Context;
import android.graphics.Color;
import android.graphics.RenderEffect;
import android.graphics.RenderNode;
import android.graphics.RuntimeShader;
import android.os.Build;
import android.view.View;

import androidx.annotation.RequiresApi;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

/**
 * Controller for the Liquid Glass RuntimeShader (Android 13+ / API 33+).
 * Binds geometric bounds, refractive index, thickness, and real-time
 * Angle (0°-360°) and Intensity (0%-150%) uniforms.
 */
@RequiresApi(api = Build.VERSION_CODES.TIRAMISU)
public class LiquidGlassEffect {

    // Default Crown Glass Refraction Index (n = 1.50)
    public static final float DEFAULT_REFRACT_INDEX = 1.50f;
    public static final float DEFAULT_THICKNESS_DP = 11.0f;
    public static final float BASE_INTENSITY = 0.75f;

    private final RuntimeShader shader;
    private RenderEffect effect;

    // Cached uniforms to prevent redundant JNI bridge calls
    private float resolutionX, resolutionY;
    private float centerX, centerY;
    private float sizeX, sizeY;
    private float radiusRB, radiusRT, radiusLB, radiusLT;
    private float thickness;
    private float intensity;
    private float angle;
    private float index;
    private int foregroundColor;

    /**
     * Creates a LiquidGlassEffect instance using the provided AGSL shader source code.
     */
    public LiquidGlassEffect(String shaderCode) {
        this.shader = new RuntimeShader(shaderCode);
    }

    /**
     * Helper to load the shader from res/raw/liquid_glass_shader.agsl or assets.
     */
    public static LiquidGlassEffect fromRawResource(Context context, int rawResId) {
        try (InputStream is = context.getResources().openRawResource(rawResId);
             BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }
            return new LiquidGlassEffect(sb.toString());
        } catch (Exception e) {
            throw new RuntimeException("Failed to load liquid glass shader", e);
        }
    }

    /**
     * Updates shader uniforms and returns the compiled RenderEffect.
     */
    public RenderEffect update(
            float width, float height,
            float left, float top, float right, float bottom,
            float radiusLT, float radiusRT, float radiusRB, float radiusLB,
            float thicknessPx,
            float baseIntensity,
            float refractIndex,
            int angleDegrees,
            int intensityPercent,
            int tintColor
    ) {
        float centerX = (left + right) / 2.0f;
        float centerY = (top + bottom) / 2.0f;
        float sizeX = (right - left) / 2.0f;
        float sizeY = (bottom - top) / 2.0f;

        // Constraint check for corner radii
        if (radiusLT + radiusLB > height) {
            float a = radiusLT / (radiusLT + radiusLB);
            radiusLT = height * a;
            radiusLB = height * (1.0f - a);
        }
        if (radiusRT + radiusRB > height) {
            float a = radiusRT / (radiusRT + radiusRB);
            radiusRT = height * a;
            radiusRB = height * (1.0f - a);
        }

        // Compute angle in radians and scaled intensity
        float configuredAngle = (float) Math.toRadians(angleDegrees);
        float configuredIntensity = baseIntensity * (intensityPercent / 75.0f);

        boolean needUpdate =
                Math.abs(this.resolutionX - width) > 0.1f ||
                Math.abs(this.resolutionY - height) > 0.1f ||
                Math.abs(this.centerX - centerX) > 0.1f ||
                Math.abs(this.centerY - centerY) > 0.1f ||
                Math.abs(this.sizeX - sizeX) > 0.1f ||
                Math.abs(this.sizeY - sizeY) > 0.1f ||
                Math.abs(this.radiusLT - radiusLT) > 0.1f ||
                Math.abs(this.radiusRT - radiusRT) > 0.1f ||
                Math.abs(this.radiusRB - radiusRB) > 0.1f ||
                Math.abs(this.radiusLB - radiusLB) > 0.1f ||
                Math.abs(this.thickness - thicknessPx) > 0.1f ||
                Math.abs(this.intensity - configuredIntensity) > 0.001f ||
                Math.abs(this.angle - configuredAngle) > 0.001f ||
                Math.abs(this.index - refractIndex) > 0.01f ||
                this.foregroundColor != tintColor ||
                effect == null;

        if (needUpdate) {
            this.foregroundColor = tintColor;

            final float a = Color.alpha(tintColor) / 255.0f;
            final float r = Color.red(tintColor) / 255.0f * a;
            final float g = Color.green(tintColor) / 255.0f * a;
            final float b = Color.blue(tintColor) / 255.0f * a;

            shader.setFloatUniform("resolution", this.resolutionX = width, this.resolutionY = height);
            shader.setFloatUniform("center", this.centerX = centerX, this.centerY = centerY);
            shader.setFloatUniform("size", this.sizeX = sizeX, this.sizeY = sizeY);
            shader.setFloatUniform("radius", this.radiusRB = radiusRB, this.radiusRT = radiusRT,
                    this.radiusLB = radiusLB, this.radiusLT = radiusLT);
            shader.setFloatUniform("thickness", this.thickness = thicknessPx);
            shader.setFloatUniform("refract_intensity", this.intensity = configuredIntensity);
            shader.setFloatUniform("refract_angle", this.angle = configuredAngle);
            shader.setFloatUniform("refract_index", this.index = refractIndex);
            shader.setFloatUniform("foreground_color_premultiplied", r, g, b, a);

            effect = RenderEffect.createRuntimeShaderEffect(shader, "img");
        }

        return effect;
    }

    /**
     * Convenience method to attach this effect directly to an Android View.
     */
    public void applyToView(View view, float cornerRadiusPx, int tintColor, int angleDegrees, int intensityPercent) {
        if (view == null || view.getWidth() == 0 || view.getHeight() == 0) return;

        float w = view.getWidth();
        float h = view.getHeight();
        float density = view.getResources().getDisplayMetrics().density;
        float thickness = Math.max(Math.min(DEFAULT_THICKNESS_DP * density, Math.min(w, h) / 5.0f), 1.0f);

        RenderEffect renderEffect = update(
                w, h,
                0, 0, w, h,
                cornerRadiusPx, cornerRadiusPx, cornerRadiusPx, cornerRadiusPx,
                thickness,
                BASE_INTENSITY,
                DEFAULT_REFRACT_INDEX,
                angleDegrees,
                intensityPercent,
                tintColor
        );

        view.setRenderEffect(renderEffect);
    }

    /**
     * Convenience method to attach this effect to a hardware RenderNode.
     */
    public void applyToRenderNode(RenderNode node, float left, float top, float right, float bottom,
                                 float cornerRadiusPx, float density, int tintColor,
                                 int angleDegrees, int intensityPercent) {
        if (node == null) return;
        float w = right - left;
        float h = bottom - top;
        float thickness = Math.max(Math.min(DEFAULT_THICKNESS_DP * density, Math.min(w, h) / 5.0f), 1.0f);

        RenderEffect renderEffect = update(
                node.getWidth(), node.getHeight(),
                left, top, right, bottom,
                cornerRadiusPx, cornerRadiusPx, cornerRadiusPx, cornerRadiusPx,
                thickness,
                BASE_INTENSITY,
                DEFAULT_REFRACT_INDEX,
                angleDegrees,
                intensityPercent,
                tintColor
        );

        node.setRenderEffect(renderEffect);
    }
}
