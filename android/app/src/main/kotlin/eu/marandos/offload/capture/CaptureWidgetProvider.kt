package eu.marandos.offload.capture

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.SizeF
import android.widget.RemoteViews
import eu.marandos.offload.R

/**
 * Home-screen widget that opens [QuickCaptureActivity] (REQ-001). 1x1 it is a tile with the
 * capture glyph; made wider it also shows a hint (DD-019). The launcher picks the largest
 * layout that fits.
 */
class CaptureWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val capture = PendingIntent.getActivity(
            context,
            0,
            Intent(context, QuickCaptureActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        fun layout(id: Int) = RemoteViews(context.packageName, id).apply {
            setOnClickPendingIntent(android.R.id.background, capture)
        }
        val views = RemoteViews(
            mapOf(
                SizeF(40f, 40f) to layout(R.layout.widget_capture),
                SizeF(WIDE_MIN_WIDTH_DP, 40f) to layout(R.layout.widget_capture_wide),
            ),
        )
        ids.forEach { manager.updateAppWidget(it, views) }
    }

    private companion object {
        /** Narrower than this, the hint would be cut off after a word or two. */
        const val WIDE_MIN_WIDTH_DP = 180f
    }
}
