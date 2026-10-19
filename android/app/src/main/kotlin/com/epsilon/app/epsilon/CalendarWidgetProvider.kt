package com.epsilon.app.epsilon

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class CalendarWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_PREV_MONTH = "com.epsilon.app.ACTION_PREV_MONTH"
        const val ACTION_NEXT_MONTH = "com.epsilon.app.ACTION_NEXT_MONTH"
        const val ACTION_TODAY = "com.epsilon.app.ACTION_TODAY"
        const val ACTION_REFRESH_WIDGET = "com.epsilon.app.ACTION_REFRESH_WIDGET"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, CalendarWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            val intent = Intent(context, CalendarWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("epsilon_widget_prefs", Context.MODE_PRIVATE)
        val monthOffset = prefs.getInt("month_offset", 0)

        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, monthOffset)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val prefs = context.getSharedPreferences("epsilon_widget_prefs", Context.MODE_PRIVATE)
        var offset = prefs.getInt("month_offset", 0)

        when (intent.action) {
            ACTION_PREV_MONTH -> {
                offset--
                prefs.edit().putInt("month_offset", offset).apply()
                updateAllWidgets(context)
            }
            ACTION_NEXT_MONTH -> {
                offset++
                prefs.edit().putInt("month_offset", offset).apply()
                updateAllWidgets(context)
            }
            ACTION_TODAY -> {
                offset = 0
                prefs.edit().putInt("month_offset", 0).apply()
                updateAllWidgets(context)
            }
            ACTION_REFRESH_WIDGET -> {
                updateAllWidgets(context)
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        monthOffset: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.calendar_app_widget)

        // Target Calendar based on offset
        val targetCal = Calendar.getInstance().apply {
            add(Calendar.MONTH, monthOffset)
        }

        val monthFormat = SimpleDateFormat("MMM", Locale.US)
        val monthTitle = monthFormat.format(targetCal.time).uppercase()
        views.setTextViewText(R.id.widget_month_title, monthTitle)

        val todayCal = Calendar.getInstance()
        views.setTextViewText(R.id.btn_today, "${todayCal.get(Calendar.DAY_OF_MONTH)}")

        // Setup PendingIntents
        views.setOnClickPendingIntent(
            R.id.btn_prev_month,
            getPendingSelfIntent(context, ACTION_PREV_MONTH)
        )
        views.setOnClickPendingIntent(
            R.id.btn_next_month,
            getPendingSelfIntent(context, ACTION_NEXT_MONTH)
        )
        views.setOnClickPendingIntent(
            R.id.btn_today,
            getPendingSelfIntent(context, ACTION_TODAY)
        )

        // Launch app on widget tap
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val launchPendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_calendar_canvas, launchPendingIntent)

        // Load events from SharedPreferences
        val eventsMap = loadEventsByDay(context)

        // Render Calendar Canvas
        val bitmap = renderCalendarBitmap(targetCal, todayCal, eventsMap)
        views.setImageViewBitmap(R.id.widget_calendar_canvas, bitmap)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getPendingSelfIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, CalendarWidgetProvider::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun loadEventsByDay(context: Context): Map<String, List<WidgetEventItem>> {
        val map = mutableMapOf<String, MutableList<WidgetEventItem>>()

        // Try reading custom saved widget events JSON
        val widgetPrefs = context.getSharedPreferences("epsilon_widget_prefs", Context.MODE_PRIVATE)
        val eventsJsonStr = widgetPrefs.getString("events_json", null)

        if (!eventsJsonStr.isNullOrEmpty()) {
            try {
                val array = JSONArray(eventsJsonStr)
                val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)

                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val title = obj.optString("title", "Event")
                    val pluginId = obj.optString("pluginId", "general")
                    val startStr = obj.optString("startTime", "")

                    val date = try {
                        if (startStr.contains("T")) {
                            isoFormat.parse(startStr.substring(0, 19))
                        } else {
                            Date(startStr.toLong())
                        }
                    } catch (_: Exception) {
                        null
                    }

                    val tagColor = if (obj.has("tagColor")) obj.optString("tagColor") else null
                    val textColor = if (obj.has("textColor")) obj.optString("textColor") else null

                    if (date != null) {
                        val key = sdf.format(date)
                        map.getOrPut(key) { mutableListOf() }
                            .add(WidgetEventItem(title, pluginId, date, tagColor, textColor))
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // Also fallback to read alarms SharedPreferences
        val alarmsPrefs = context.getSharedPreferences("epsilon_alarms_prefs", Context.MODE_PRIVATE)
        val allAlarms = alarmsPrefs.all
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)

        for ((_, value) in allAlarms) {
            if (value is String) {
                try {
                    val json = JSONObject(value)
                    val epoch = json.optLong("epochMillis", 0L)
                    val title = json.optString("title", "Contest Alarm")
                    if (epoch > 0) {
                        val d = Date(epoch)
                        val key = sdf.format(d)
                        if (!map.containsKey(key)) {
                            map.getOrPut(key) { mutableListOf() }
                                .add(WidgetEventItem(title, "cp_contest", d, "#00E5FF", "#000000"))
                        }
                    }
                } catch (_: Exception) {}
            }
        }

        return map
    }

    private fun renderCalendarBitmap(
        monthCal: Calendar,
        todayCal: Calendar,
        eventsMap: Map<String, List<WidgetEventItem>>
    ): Bitmap {
        val width = 460
        val height = 420
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val textBounds = Rect()

        // 1. Draw Weekday Headers: M T W T F S S
        val weekdays = arrayOf("M", "T", "W", "T", "F", "S", "S")
        val colWidth = width / 7f
        paint.textSize = 19f
        paint.isFakeBoldText = true

        val headerY = 24f
        for (i in 0 until 7) {
            val letter = weekdays[i]
            paint.color = if (i == 6) Color.parseColor("#FF5252") else Color.parseColor("#B3FFFFFF")
            paint.getTextBounds(letter, 0, letter.length, textBounds)
            val x = i * colWidth + (colWidth - textBounds.width()) / 2f
            canvas.drawText(letter, x, headerY, paint)
        }

        // Thin divider below weekday headers
        paint.color = Color.parseColor("#1AFFFFFF")
        paint.strokeWidth = 1.5f
        paint.style = Paint.Style.STROKE
        canvas.drawLine(8f, 34f, width - 8f, 34f, paint)

        // 2. Compute Days Grid
        val cal = (monthCal.clone() as Calendar).apply {
            set(Calendar.DAY_OF_MONTH, 1)
        }

        val firstDayOfWeek = cal.get(Calendar.DAY_OF_WEEK)
        val leadingDays = (firstDayOfWeek + 5) % 7
        val daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)

        val prevMonthCal = (cal.clone() as Calendar).apply {
            add(Calendar.MONTH, -1)
        }
        val prevMonthDays = prevMonthCal.getActualMaximum(Calendar.DAY_OF_MONTH)

        val totalCells = Math.ceil(((leadingDays + daysInMonth) / 7.0)).toInt() * 7
        val rowHeight = (height - 40f) / (totalCells / 7)
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)

        val pillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }
        val pillTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 13f
            isFakeBoldText = true
        }

        val todayBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.WHITE
            strokeWidth = 2.5f
        }

        for (index in 0 until totalCells) {
            val col = index % 7
            val row = index / 7
            val cellLeft = col * colWidth
            val cellTop = 40f + row * rowHeight
            val cellRight = cellLeft + colWidth
            val cellBottom = cellTop + rowHeight

            val cellCal = Calendar.getInstance()
            var isCurrentMonth = false

            if (index < leadingDays) {
                val dayNum = prevMonthDays - leadingDays + 1 + index
                cellCal.time = prevMonthCal.time
                cellCal.set(Calendar.DAY_OF_MONTH, dayNum)
            } else if (index < leadingDays + daysInMonth) {
                val dayNum = index - leadingDays + 1
                cellCal.time = monthCal.time
                cellCal.set(Calendar.DAY_OF_MONTH, dayNum)
                isCurrentMonth = true
            } else {
                val dayNum = index - (leadingDays + daysInMonth) + 1
                cellCal.time = monthCal.time
                cellCal.add(Calendar.MONTH, 1)
                cellCal.set(Calendar.DAY_OF_MONTH, dayNum)
            }

            val isToday = cellCal.get(Calendar.YEAR) == todayCal.get(Calendar.YEAR) &&
                    cellCal.get(Calendar.DAY_OF_YEAR) == todayCal.get(Calendar.DAY_OF_YEAR)

            val isSunday = col == 6
            val dayNumStr = "${cellCal.get(Calendar.DAY_OF_MONTH)}"

            // Draw today rounded border box
            if (isToday) {
                val boxRect = RectF(cellLeft + 3f, cellTop + 1f, cellRight - 3f, cellBottom - 1f)
                canvas.drawRoundRect(boxRect, 10f, 10f, todayBorderPaint)
            }

            // Draw date number
            paint.style = Paint.Style.FILL
            paint.textSize = 17f
            paint.isFakeBoldText = isToday
            if (!isCurrentMonth) {
                paint.color = if (isSunday) Color.parseColor("#55FF5252") else Color.parseColor("#40FFFFFF")
            } else if (isSunday) {
                paint.color = Color.parseColor("#FF5252")
            } else {
                paint.color = Color.WHITE
            }

            paint.getTextBounds(dayNumStr, 0, dayNumStr.length, textBounds)
            val dateX = cellLeft + (colWidth - textBounds.width()) / 2f
            val dateY = cellTop + textBounds.height() + 7f
            canvas.drawText(dayNumStr, dateX, dateY, paint)

            // Draw Event Pills for this day (supports multiple stacked pills)
            val dayKey = sdf.format(cellCal.time)
            val dayEvents = eventsMap[dayKey]

            if (!dayEvents.isNullOrEmpty()) {
                val pillMarginH = 3.5f
                val count = dayEvents.size

                if (count == 1) {
                    // Single Event Pill (roomier height)
                    val ev = dayEvents[0]
                    val pColor = parseColorSafe(ev.tagColor, if (ev.pluginId == "test") "#7C4DFF" else "#2979FF")
                    val tColor = parseColorSafe(ev.textColor, if (ev.pluginId == "test") "#FFFFFF" else "#FFFFFF")

                    pillPaint.color = pColor
                    pillTextPaint.color = tColor
                    pillTextPaint.textSize = 12f

                    val pillTop = dateY + 3.5f
                    val pillBottom = Math.min(pillTop + 16f, cellBottom - 2.5f)
                    val pillRect = RectF(cellLeft + pillMarginH, pillTop, cellRight - pillMarginH, pillBottom)
                    canvas.drawRoundRect(pillRect, 5f, 5f, pillPaint)

                    val maxChars = 7
                    val shortTitle = if (ev.title.length > maxChars) ev.title.substring(0, maxChars) + ".." else ev.title
                    val textX = pillRect.left + 3.5f
                    val textY = pillRect.centerY() + 4f
                    canvas.drawText(shortTitle, textX, textY, pillTextPaint)
                } else {
                    // Two or More Events: Stacked compact pills!
                    val maxPills = 2
                    val pillH = 11.5f
                    val gap = 1.5f

                    for (pIndex in 0 until Math.min(count, maxPills)) {
                        val ev = dayEvents[pIndex]
                        val pColor = parseColorSafe(ev.tagColor, if (ev.pluginId == "test") "#7C4DFF" else "#2979FF")
                        val tColor = parseColorSafe(ev.textColor, if (ev.pluginId == "test") "#FFFFFF" else "#FFFFFF")

                        pillPaint.color = pColor
                        pillTextPaint.color = tColor
                        pillTextPaint.textSize = 9.5f

                        val pillTop = dateY + 2f + pIndex * (pillH + gap)
                        val pillBottom = Math.min(pillTop + pillH, cellBottom - 1.5f)
                        val pillRect = RectF(cellLeft + pillMarginH, pillTop, cellRight - pillMarginH, pillBottom)
                        canvas.drawRoundRect(pillRect, 4f, 4f, pillPaint)

                        var title = ev.title
                        val hasMore = (pIndex == maxPills - 1) && (count > maxPills)
                        val extraSuffix = if (hasMore) "+${count - 1}" else ""

                        val maxChars = if (hasMore) 4 else 6
                        val shortTitle = if (title.length > maxChars) title.substring(0, maxChars) + ".." else title
                        val displayStr = if (hasMore) "$shortTitle $extraSuffix" else shortTitle

                        val textX = pillRect.left + 3f
                        val textY = pillRect.centerY() + 3.5f
                        canvas.drawText(displayStr, textX, textY, pillTextPaint)
                    }
                }
            }
        }

        return bitmap
    }

    private fun parseColorSafe(colorStr: String?, defaultHex: String): Int {
        if (!colorStr.isNullOrEmpty()) {
            try {
                var clean = colorStr.trim()
                if (!clean.startsWith("#")) clean = "#$clean"
                return Color.parseColor(clean)
            } catch (_: Exception) {}
        }
        return Color.parseColor(defaultHex)
    }
}

data class WidgetEventItem(
    val title: String,
    val pluginId: String,
    val date: Date,
    val tagColor: String? = null,
    val textColor: String? = null
)

