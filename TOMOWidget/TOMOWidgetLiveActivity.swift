//
//  TOMOWidgetLiveActivity.swift
//  TOMOWidget
//
//  Created by KG on 6/9/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TOMOWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TOMOWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TOMOWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TOMOWidgetAttributes {
    fileprivate static var preview: TOMOWidgetAttributes {
        TOMOWidgetAttributes(name: "World")
    }
}

extension TOMOWidgetAttributes.ContentState {
    fileprivate static var smiley: TOMOWidgetAttributes.ContentState {
        TOMOWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TOMOWidgetAttributes.ContentState {
         TOMOWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TOMOWidgetAttributes.preview) {
   TOMOWidgetLiveActivity()
} contentStates: {
    TOMOWidgetAttributes.ContentState.smiley
    TOMOWidgetAttributes.ContentState.starEyes
}
