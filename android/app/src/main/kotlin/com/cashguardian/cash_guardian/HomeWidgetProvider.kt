package com.cashguardian.cash_guardian

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.jetbrains.annotations.NotNull

class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        @NotNull appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.home_widget_layout)

            val spent = widgetData.getString("spent", "0")
            val budget = widgetData.getString("budget", "500")
            val wasted = widgetData.getString("wasted", "0")
            val progress = widgetData.getString("progress", "0")

            views.setTextViewText(R.id.widget_amount, "ETB $spent")
            views.setTextViewText(R.id.widget_budget, "Budget: ETB $budget")
            views.setTextViewText(R.id.widget_wasted, "Wasted: ETB $wasted")
            views.setProgressBar(R.id.widget_progress, 100, progress.toIntOrNull() ?: 0, false)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
