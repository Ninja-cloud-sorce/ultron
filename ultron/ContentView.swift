//
//  ContentView.swift
//  ultron
//
//  Created by praful on 7/21/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ultronDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(ultronDocument()))
}
