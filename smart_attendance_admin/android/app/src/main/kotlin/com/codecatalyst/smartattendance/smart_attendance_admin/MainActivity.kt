package com.codecatalyst.smartattendance.smart_attendance_admin

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "smart_attendance/ble_advertiser"
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val bluetoothAdapter = bluetoothManager.adapter
        bluetoothLeAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdvertising" -> {
                    val uuid = call.argument<String>("uuid")
                    if (uuid != null) {
                        val success = startAdvertising(uuid)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "UUID is required", null)
                    }
                }
                "stopAdvertising" -> {
                    stopAdvertising()
                    result.success(true)
                }
                "isAdvertisingSupported" -> {
                    result.success(bluetoothLeAdvertiser != null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startAdvertising(uuidString: String): Boolean {
        if (bluetoothLeAdvertiser == null) {
            return false
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(UUID.fromString(uuidString)))
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                super.onStartSuccess(settingsInEffect)
                println("✅ BLE Advertising started for UUID: $uuidString")
            }

            override fun onStartFailure(errorCode: Int) {
                super.onStartFailure(errorCode)
                println("❌ BLE Advertising failed with error: $errorCode")
            }
        }

        try {
            bluetoothLeAdvertiser?.startAdvertising(settings, data, advertiseCallback)
            return true
        } catch (e: Exception) {
            println("Exception starting advertising: ${e.message}")
            return false
        }
    }

    private fun stopAdvertising() {
        try {
            advertiseCallback?.let {
                bluetoothLeAdvertiser?.stopAdvertising(it)
                advertiseCallback = null
            }
            println("🛑 BLE Advertising stopped")
        } catch (e: Exception) {
            println("Exception stopping advertising: ${e.message}")
        }
    }

    override fun onDestroy() {
        stopAdvertising()
        super.onDestroy()
    }
}
