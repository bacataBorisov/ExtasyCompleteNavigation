//
//  LayoutUtilities.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 25.11.24.
//

import SwiftUI
//MARK: - Awesome Function for Resizing by Passing a View

public struct VHStack<Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        //LandscapeView
        if verticalSizeClass == .compact {
            HStack() {
                content
            }
            .safeAreaPadding(.top)
        //PortraitView
        } else {
            VStack {
                content
            }
            .safeAreaPadding(.all)
        }
    }
}

//Used for ScrollView Purposes
public struct HVStack<Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        //LandscapeView
        if verticalSizeClass == .compact {
            VStack() {
                content
            }
            //.safeAreaPadding(.all)
        //PortraitView
        } else {
            HStack {
                content
            }
            //.safeAreaPadding(.top)
        }
    }
}
