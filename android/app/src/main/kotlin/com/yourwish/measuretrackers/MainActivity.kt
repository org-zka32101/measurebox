package com.yourwish.measuretrackers

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Illuminance (ambient light) measurement, implemented directly here rather
 * than via a third-party Flutter plugin. The maintained light-sensor
 * plugins on pub.dev ship native Android Gradle build files pinned to an
 * old configuration (`jcenter()`, pre-AGP-9 DSL) that fails to build
 * against this project's AGP 9.0.1 / Gradle 9.1.0 toolchain — see
 * lib/services/illuminance_service.dart's doc comment for the full story.
 * This is ~40 lines of plain `SensorManager` usage, so owning it here
 * avoids depending on an unmaintained plugin's build.gradle for a single
 * sensor reading.
 */
class MainActivity : FlutterActivity() {
    private val illuminanceMethodChannel =
        "com.yourwish.measuretrackers/illuminance"
    private val illuminanceEventChannel =
        "com.yourwish.measuretrackers/illuminance/stream"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val sensorManager =
            getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            illuminanceMethodChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSensor" -> result.success(lightSensor != null)
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            illuminanceEventChannel,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var listener: SensorEventListener? = null

                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink,
                ) {
                    if (lightSensor == null) {
                        events.error(
                            "NO_SENSOR",
                            "Device has no light sensor",
                            null,
                        )
                        return
                    }
                    val sensorEventListener =
                        object : SensorEventListener {
                            override fun onSensorChanged(event: SensorEvent) {
                                events.success(event.values[0].toDouble())
                            }

                            override fun onAccuracyChanged(
                                sensor: Sensor?,
                                accuracy: Int,
                            ) {}
                        }
                    listener = sensorEventListener
                    sensorManager.registerListener(
                        sensorEventListener,
                        lightSensor,
                        SensorManager.SENSOR_DELAY_NORMAL,
                    )
                }

                override fun onCancel(arguments: Any?) {
                    listener?.let { sensorManager.unregisterListener(it) }
                    listener = null
                }
            },
        )
    }
}
