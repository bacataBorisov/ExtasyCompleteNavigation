//
//  GeometryProvider.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 22.11.24.
//


import SwiftUI

struct GeometryProvider<Content: View>: View {
    let content: (CGFloat, GeometryProxy, CGFloat) -> Content // Closure with width and height
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height)
            let height = max(geometry.size.width, geometry.size.height)
            content(width, geometry, height) // Pass these values to the content
        }
    }
}
