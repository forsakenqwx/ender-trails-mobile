package com.endertrails.ender_trails

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val APPS_CHANNEL = "online.endertrails.vpn/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstalledApps") {
                Thread {
                    try {
                        val pm = packageManager
                        val seenPackages = HashSet<String>()
                        val appsList = ArrayList<Map<String, Any>>()

                        // Высокопроизводительный буфер 20x20 для процедурной генерации пиксельных иконок
                        val iconPixelSize = 20
                        val pixelBitmap = Bitmap.createBitmap(iconPixelSize, iconPixelSize, Bitmap.Config.ARGB_8888)
                        val canvas = Canvas(pixelBitmap)
                        val byteStream = ByteArrayOutputStream()

                        // 1. Сначала собираем все приложения с лаунчер-активностями (пользовательский рабочий стол)
                        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val launcherActivities = pm.queryIntentActivities(launcherIntent, 0)
                        for (resolveInfo in launcherActivities) {
                            val pkgName = resolveInfo.activityInfo.packageName
                            if (seenPackages.contains(pkgName) || pkgName == packageName) continue
                            seenPackages.add(pkgName)

                            val appName = resolveInfo.loadLabel(pm).toString()
                            val isSystem = (resolveInfo.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                            // Процедурно отрисовываем пиксель-арт иконку 20x20
                            var iconBytes: ByteArray? = null
                            try {
                                val drawable = resolveInfo.loadIcon(pm)
                                pixelBitmap.eraseColor(Color.TRANSPARENT)
                                drawable.setBounds(0, 0, iconPixelSize, iconPixelSize)
                                drawable.draw(canvas)
                                byteStream.reset()
                                pixelBitmap.compress(Bitmap.CompressFormat.PNG, 85, byteStream)
                                iconBytes = byteStream.toByteArray()
                            } catch (_: Exception) {}

                            val appMap = HashMap<String, Any>()
                            appMap["name"] = appName
                            appMap["package"] = pkgName
                            appMap["isSystem"] = isSystem
                            if (iconBytes != null && iconBytes.isNotEmpty()) {
                                appMap["icon"] = iconBytes
                            }
                            appsList.add(appMap)
                        }

                        // 2. Дополняем всеми остальными установленными приложениями на телефоне (QUERY_ALL_PACKAGES)
                        val allInstalled = pm.getInstalledApplications(0)
                        for (appInfo in allInstalled) {
                            val pkgName = appInfo.packageName
                            if (seenPackages.contains(pkgName) || pkgName == packageName) continue
                            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                            // Для системных пакетов без лаунчера оставляем только те, у которых есть доступ в интернет
                            if (isSystem && pm.checkPermission(android.Manifest.permission.INTERNET, pkgName) != PackageManager.PERMISSION_GRANTED) {
                                continue
                            }
                            seenPackages.add(pkgName)

                            val appName = pm.getApplicationLabel(appInfo).toString()

                            var iconBytes: ByteArray? = null
                            try {
                                val drawable = appInfo.loadIcon(pm)
                                pixelBitmap.eraseColor(Color.TRANSPARENT)
                                drawable.setBounds(0, 0, iconPixelSize, iconPixelSize)
                                drawable.draw(canvas)
                                byteStream.reset()
                                pixelBitmap.compress(Bitmap.CompressFormat.PNG, 85, byteStream)
                                iconBytes = byteStream.toByteArray()
                            } catch (_: Exception) {}

                            val appMap = HashMap<String, Any>()
                            appMap["name"] = appName
                            appMap["package"] = pkgName
                            appMap["isSystem"] = isSystem
                            if (iconBytes != null && iconBytes.isNotEmpty()) {
                                appMap["icon"] = iconBytes
                            }
                            appsList.add(appMap)
                        }

                        pixelBitmap.recycle()

                        // Сортировка: сначала пользовательские приложения, затем по алфавиту
                        appsList.sortWith(Comparator { a, b ->
                            val aSys = a["isSystem"] as? Boolean ?: false
                            val bSys = b["isSystem"] as? Boolean ?: false
                            if (aSys != bSys) {
                                if (!aSys) -1 else 1
                            } else {
                                val aName = (a["name"] as? String ?: "").lowercase()
                                val bName = (b["name"] as? String ?: "").lowercase()
                                aName.compareTo(bName)
                            }
                        })

                        runOnUiThread {
                            result.success(appsList)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("APPS_ERROR", e.message, null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }
}
