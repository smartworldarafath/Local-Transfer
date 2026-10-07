package com.example.liquidglass;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Manages Liquid Glass user preferences (Angle & Intensity)
 * and notifies active listeners for real-time shader updates.
 */
public class LiquidGlassConfig {

    private static final String PREF_NAME = "liquid_glass_config";
    private static final String KEY_ANGLE = "liquid_glass_angle";         // 0° to 360°
    private static final String KEY_INTENSITY = "liquid_glass_intensity"; // 0% to 150%

    public static final int DEFAULT_ANGLE = 0;       // 0 degrees
    public static final int DEFAULT_INTENSITY = 75;  // 75% (1.0x baseline intensity)

    public static final int MAX_ANGLE = 360;
    public static final int MAX_INTENSITY = 150;

    public interface OnConfigChangeListener {
        void onConfigChanged(int angleDegrees, int intensityPercent);
    }

    private static volatile LiquidGlassConfig instance;
    private final SharedPreferences preferences;
    private final CopyOnWriteArrayList<OnConfigChangeListener> listeners = new CopyOnWriteArrayList<>();

    private int angle;
    private int intensity;

    public static LiquidGlassConfig get(Context context) {
        if (instance == null) {
            synchronized (LiquidGlassConfig.class) {
                if (instance == null) {
                    instance = new LiquidGlassConfig(context.getApplicationContext());
                }
            }
        }
        return instance;
    }

    private LiquidGlassConfig(Context context) {
        preferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        angle = preferences.getInt(KEY_ANGLE, DEFAULT_ANGLE);
        intensity = preferences.getInt(KEY_INTENSITY, DEFAULT_INTENSITY);
    }

    public int getAngle() {
        return angle;
    }

    public float getAngleRadians() {
        return (float) Math.toRadians(angle);
    }

    public void setAngle(int angleDegrees) {
        int clamped = Math.max(0, Math.min(MAX_ANGLE, angleDegrees));
        if (this.angle != clamped) {
            this.angle = clamped;
            preferences.edit().putInt(KEY_ANGLE, clamped).apply();
            notifyListeners();
        }
    }

    public int getIntensity() {
        return intensity;
    }

    /**
     * Normalized intensity factor: 75% = 1.0f factor.
     */
    public float getNormalizedIntensity(float baseIntensity) {
        return baseIntensity * (intensity / 75.0f);
    }

    public void setIntensity(int intensityPercent) {
        int clamped = Math.max(0, Math.min(MAX_INTENSITY, intensityPercent));
        if (this.intensity != clamped) {
            this.intensity = clamped;
            preferences.edit().putInt(KEY_INTENSITY, clamped).apply();
            notifyListeners();
        }
    }

    public void addListener(OnConfigChangeListener listener) {
        if (listener != null && !listeners.contains(listener)) {
            listeners.add(listener);
        }
    }

    public void removeListener(OnConfigChangeListener listener) {
        if (listener != null) {
            listeners.remove(listener);
        }
    }

    private void notifyListeners() {
        for (OnConfigChangeListener listener : listeners) {
            listener.onConfigChanged(angle, intensity);
        }
    }
}
