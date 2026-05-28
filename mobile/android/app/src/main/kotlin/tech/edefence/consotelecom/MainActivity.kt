package tech.edefence.consotelecom

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.os.Build
import android.os.Process
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL = "tech.edefence.consotelecom/network"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNetworkStatsTotal" -> {
                    try {
                        val stats = getNetworkStatsTotal()
                        result.success(stats)
                    } catch (e: Exception) {
                        result.error("NETWORK_STATS_ERROR", e.message, null)
                    }
                }
                "getNetworkStatsPerApp" -> {
                    try {
                        val stats = getNetworkStatsPerApp()
                        result.success(stats)
                    } catch (e: Exception) {
                        result.error("NETWORK_STATS_PER_APP_ERROR", e.message, null)
                    }
                }
                "dialUssd" -> {
                    val code = call.argument<String>("code")
                    if (code == null) {
                        result.error("INVALID_ARG", "code est requis", null)
                    } else {
                        try {
                            val response = dialUssd(code)
                            result.success(response)
                        } catch (e: Exception) {
                            result.error("USSD_ERROR", e.message, null)
                        }
                    }
                }
                "getSimInfo" -> {
                    try {
                        val simInfo = getSimInfo()
                        result.success(simInfo)
                    } catch (e: Exception) {
                        result.error("SIM_INFO_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getNetworkStatsTotal(): String {
        if (!hasUsageStatsPermission()) {
            throw SecurityException("Permission PACKAGE_USAGE_STATS non accordée")
        }

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis

        // Stats mobile
        var mobileRx = 0L
        var mobileTx = 0L
        try {
            val mobileStats = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_MOBILE, null, startTime, endTime
            )
            mobileRx = mobileStats.rxBytes
            mobileTx = mobileStats.txBytes
        } catch (e: Exception) {
            // Ignorer si pas de données mobiles
        }

        // Stats WiFi
        var wifiRx = 0L
        var wifiTx = 0L
        try {
            val wifiStats = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_WIFI, null, startTime, endTime
            )
            wifiRx = wifiStats.rxBytes
            wifiTx = wifiStats.txBytes
        } catch (e: Exception) {
            // Ignorer si pas de WiFi
        }

        val json = JSONObject().apply {
            put("mobile_rx_bytes", mobileRx)
            put("mobile_tx_bytes", mobileTx)
            put("wifi_rx_bytes", wifiRx)
            put("wifi_tx_bytes", wifiTx)
        }

        return json.toString()
    }

    private fun getNetworkStatsPerApp(): String {
        if (!hasUsageStatsPermission()) {
            throw SecurityException("Permission PACKAGE_USAGE_STATS non accordée")
        }

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val pm = packageManager

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis

        val appStatsMap = mutableMapOf<Int, AppNetworkStats>()

        // Stats mobile par app
        try {
            val mobileBucket = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_MOBILE, null, startTime, endTime
            )
            val bucket = NetworkStats.Bucket()
            while (mobileBucket.hasNextBucket()) {
                mobileBucket.getNextBucket(bucket)
                val uid = bucket.uid
                if (uid >= 10000) { // apps utilisateur seulement
                    val stats = appStatsMap.getOrPut(uid) { AppNetworkStats(uid) }
                    stats.mobileRx += bucket.rxBytes
                    stats.mobileTx += bucket.txBytes
                }
            }
            mobileBucket.close()
        } catch (e: Exception) {
            // Continuer sans stats mobile
        }

        // Stats WiFi par app
        try {
            val wifiBucket = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_WIFI, null, startTime, endTime
            )
            val bucket = NetworkStats.Bucket()
            while (wifiBucket.hasNextBucket()) {
                wifiBucket.getNextBucket(bucket)
                val uid = bucket.uid
                if (uid >= 10000) {
                    val stats = appStatsMap.getOrPut(uid) { AppNetworkStats(uid) }
                    stats.wifiRx += bucket.rxBytes
                    stats.wifiTx += bucket.txBytes
                }
            }
            wifiBucket.close()
        } catch (e: Exception) {
            // Continuer sans stats WiFi
        }

        val jsonArray = JSONArray()
        for ((uid, stats) in appStatsMap) {
            try {
                val packages = pm.getPackagesForUid(uid) ?: continue
                val packageName = packages[0]
                val appInfo = pm.getApplicationInfo(packageName, 0)
                val appName = pm.getApplicationLabel(appInfo).toString()

                val obj = JSONObject().apply {
                    put("package_name", packageName)
                    put("app_name", appName)
                    put("mobile_rx", stats.mobileRx)
                    put("mobile_tx", stats.mobileTx)
                    put("wifi_rx", stats.wifiRx)
                    put("wifi_tx", stats.wifiTx)
                }
                jsonArray.put(obj)
            } catch (e: PackageManager.NameNotFoundException) {
                // App désinstallée, ignorer
            }
        }

        return jsonArray.toString()
    }

    private fun dialUssd(code: String): String {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        if (checkSelfPermission(android.Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            throw SecurityException("Permission CALL_PHONE non accordée")
        }

        // Formater le code USSD
        val ussdCode = if (code.endsWith("#")) code else "$code#"
        val dialUri = android.net.Uri.parse("tel:${android.net.Uri.encode(ussdCode)}")
        val intent = android.content.Intent(android.content.Intent.ACTION_CALL, dialUri)
        intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)

        return "USSD_DIALED:$ussdCode"
    }

    private fun getSimInfo(): String {
        val jsonArray = JSONArray()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            if (checkSelfPermission(android.Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                return jsonArray.toString()
            }

            try {
                val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                val subscriptions = subscriptionManager.activeSubscriptionInfoList ?: emptyList()

                for (sub in subscriptions) {
                    val obj = JSONObject().apply {
                        put("slot", sub.simSlotIndex)
                        put("carrier_name", sub.carrierName?.toString() ?: "Inconnu")
                        put("country_iso", sub.countryIso?.uppercase() ?: "BF")
                        put("subscription_id", sub.subscriptionId)
                        put("display_name", sub.displayName?.toString() ?: "SIM ${sub.simSlotIndex + 1}")
                    }
                    jsonArray.put(obj)
                }
            } catch (e: Exception) {
                // Retourner tableau vide si erreur
            }
        }

        return jsonArray.toString()
    }

    data class AppNetworkStats(
        val uid: Int,
        var mobileRx: Long = 0L,
        var mobileTx: Long = 0L,
        var wifiRx: Long = 0L,
        var wifiTx: Long = 0L
    )
}
