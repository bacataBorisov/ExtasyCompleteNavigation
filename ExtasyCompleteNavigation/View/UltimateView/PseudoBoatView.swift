//
//  PseudoBoatView.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 20.08.23.
//

import SwiftUI

struct PseudoBoatView: View {
    var body: some View {
        PseudoBoat()
            .stroke(lineWidth: 5)
            .scaleEffect(x: 0.7, y: 0.7)
    }
}

#Preview {
    PseudoBoatView()
}
