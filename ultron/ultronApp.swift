//
//  ultronApp.swift
//  ultron
//
//  Created by praful on 7/21/26.
//

import SwiftUI

@main
struct ultronApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ultronDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
