//
//  TOMOWidgetBundle.swift
//  TOMOWidget
//
//  Created by KG on 6/9/25.
//

import WidgetKit
import SwiftUI

struct TOMOWidgetBundle: WidgetBundle {
    var body: some Widget {
        TOMOWidget()
        TOMOWidgetControl()
        TOMOWidgetLiveActivity()
    }
}
