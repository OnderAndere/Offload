package eu.marandos.offload.capture

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.SizeF
import android.widget.RemoteViews
import eu.marandos.offload.OpenDestinationActivity
import eu.marandos.offload.R

/**
 * The Offload bar (REQ-063, DD-019): a second home-screen widget next to
 * [CaptureWidgetProvider]. Two cells: *Capture* and *Today*; made wider,
 * *Insights* too. *Capture* opens [QuickCaptureActivity] as the capture
 * widget does, without starting Flutter (REQ-001); *Today* and *Insights*
 * open the app on that destination ([OpenDestinationActivity.openIntent]).
 * It reads nothing and shows no counts (DD-007).
 */
class OffloadBarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val capture = PendingIntent.getActivity(
            context,
            REQUEST_CAPTURE,
            Intent(context, QuickCaptureActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        fun open(requestCode: Int, target: String) = PendingIntent.getActivity(
            context,
            requestCode,
            OpenDestinationActivity.openIntent(context, target),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val today = open(REQUEST_TODAY, OpenDestinationActivity.TODAY)
        val insights = open(REQUEST_INSIGHTS, OpenDestinationActivity.INSIGHTS)
        fun layout(id: Int) = RemoteViews(context.packageName, id).apply {
            setOnClickPendingIntent(R.id.bar_capture, capture)
            setOnClickPendingIntent(R.id.bar_today, today)
            if (id == R.layout.widget_bar_wide) {
                setOnClickPendingIntent(R.id.bar_insights, insights)
            }
        }
        val views = RemoteViews(
            mapOf(
                SizeF(100f, 40f) to layout(R.layout.widget_bar),
                SizeF(WIDE_MIN_WIDTH_DP, 40f) to layout(R.layout.widget_bar_wide),
            ),
        )
        ids.forEach { manager.updateAppWidget(it, views) }
    }

    private companion object {
        /** Three buttons of at least 48 dp each, with room for their words. */
        const val WIDE_MIN_WIDTH_DP = 180f
        const val REQUEST_CAPTURE = 0
        const val REQUEST_TODAY = 1
        const val REQUEST_INSIGHTS = 2
    }
}
