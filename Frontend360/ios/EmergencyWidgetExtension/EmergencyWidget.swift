import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        let entry = SimpleEntry(date: Date())
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

extension View {
    @ViewBuilder
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            self.background(backgroundView)
        }
    }
}

struct EmergencyWidgetEntryView : View {
    var entry: Provider.Entry

    let bgDark = Color(red: 26/255, green: 28/255, blue: 32/255)
    let bgItem = Color(red: 34/255, green: 37/255, blue: 42/255)
    let borderColor = Color(red: 45/255, green: 48/255, blue: 53/255)
    let cOrange = Color(red: 255/255, green: 107/255, blue: 43/255)
    let cBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    let cPurple = Color(red: 139/255, green: 92/255, blue: 246/255)
    let cYellow = Color(red: 234/255, green: 179/255, blue: 8/255)
    let textGrey = Color(red: 156/255, green: 163/255, blue: 175/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(cOrange)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Report")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Quick disaster alert")
                        .font(.system(size: 11))
                        .foregroundColor(textGrey)
                }
                .padding(.leading, 4)
                
                Spacer()
                
                Text("Active")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(cOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cOrange.opacity(0.2))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(cOrange, lineWidth: 1))
            }
            
            // Location Box
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(cOrange)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Location")
                        .font(.system(size: 10))
                        .foregroundColor(textGrey)
                    Text("Detected automatically")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 6)
                
                Spacer()
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            .padding(10)
            .background(bgItem)
            .cornerRadius(12)
            
            Text("Select Disaster Type")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 4)
            
            // Grid
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    GridItemView(bg: bgItem, border: borderColor, iconBg: cOrange, iconName: "flame.fill", label: "Fire")
                    GridItemView(bg: bgItem, border: borderColor, iconBg: cBlue, iconName: "drop.fill", label: "Flood")
                }
                HStack(spacing: 8) {
                    GridItemView(bg: bgItem, border: borderColor, iconBg: cPurple, iconName: "wind", label: "Storm")
                    GridItemView(bg: bgItem, border: borderColor, iconBg: cYellow, iconName: "bolt.fill", label: "Earthquake")
                }
            }
            
            // Bottom Button
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(textGrey)
                    .font(.system(size: 12))
                Text("Report Emergency Now")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textGrey)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(red: 42/255, green: 45/255, blue: 52/255))
            .cornerRadius(12)
            
            Text("🕒 24/7 Emergency Response")
                .font(.system(size: 9))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .padding(16)
        .widgetBackground(bgDark)
        .widgetURL(URL(string: "disaster360://emergency"))
    }
}

struct GridItemView: View {
    var bg: Color
    var border: Color
    var iconBg: Color
    var iconName: String
    var label: String
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                iconBg
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(bg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border, lineWidth: 1))
    }
}

@main
struct EmergencyWidget: Widget {
    let kind: String = "EmergencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EmergencyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Emergency Report")
        .description("Quickly open the app in Emergency Reporting mode.")
        .supportedFamilies([.systemLarge])
    }
}
