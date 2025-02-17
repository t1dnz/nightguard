//
//  nightguard_Widget_Extension.swift
//  nightguard Widget Extension
//
//  Created by Dirk Hermanns on 14.09.22.
//  Copyright © 2022 private. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

@main
struct NightguardWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NightguardDefaultWidgets()
        NightguardGaugeWidgets()
    }
}

struct NightguardDefaultWidgets: Widget {
    
    var provider = NightguardTimelineProvider(displayName: "BG Text")

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "org.duckdns.dhe.nightguard.NightguardDefaultWidgets",
            provider: provider
        ) { entry in
            NightguardEntryView(entry: entry)
        }
        .configurationDisplayName("Nightguard BG Values Text Complication")
        .description(provider.displayName)
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

struct NightguardGaugeWidgets: Widget {
    
    var provider = NightguardTimelineProvider(displayName: "BG Gauge")
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "org.duckdns.dhe.nightguard.NightguardGaugeWidgets",
            provider: provider
        ) { entry in
            NightguardGaugeEntryView(entry: entry)
        }
        .configurationDisplayName("Nightguard BG Values as Gauge Complication")
        .description(provider.displayName)
        .supportedFamilies([
            .accessoryCircular
        ])
    }
}

struct NightguardEntryView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    var entry: NightscoutDataEntry

    var body: some View {
        switch widgetFamily {
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryInline:
                AccessoryInlineView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            
            default:
                //mandatory as there are more widget families as in lockscreen widgets etc
                Text("Not an implemented widget yet")
        }
    }
}

struct NightguardGaugeEntryView : View {
    
    @Environment(\.widgetFamily) var widgetFamily
    var entry: NightscoutDataEntry

    var body: some View {
        switch widgetFamily {
            case .accessoryCircular:
                AccessoryCircularGaugeView(entry: entry)
            
            default:
                //mandatory as there are more widget families as in lockscreen widgets etc
                Text("No Gauge Support for this widget!")
        }
    }
}

struct nightguard_Widget_Extension_Previews: PreviewProvider {
    static var previews: some View {
        
        NightguardEntryView(entry: NightscoutDataEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")
        
        NightguardEntryView(entry: NightscoutDataEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")
        
        NightguardGaugeEntryView(entry: NightscoutDataEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")
        
        NightguardEntryView(entry: NightscoutDataEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular")
    }
}
