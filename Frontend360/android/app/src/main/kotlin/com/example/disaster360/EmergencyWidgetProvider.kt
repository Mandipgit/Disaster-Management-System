package com.example.disaster360

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class EmergencyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // Perform this loop procedure for each App Widget that belongs to this provider
        for (appWidgetId in appWidgetIds) {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("disaster360://emergency"))
            // Flags to ensure deep link opens correctly even from cold start
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

            // Create PendingIntent
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Construct the RemoteViews object
            val views = RemoteViews(context.packageName, R.layout.emergency_widget)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
