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

// MARK: - RoundedBackgroundView
public struct RoundedBackgroundView<Content: View>: View {
    let content: Content
    let sectionPadding: CGFloat = 8
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground) // Background color
                .edgesIgnoringSafeArea(.all)
            
            content
                //.padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(sectionPadding)
        }
    }
}

// MARK: - Helper Method to Determine is it running on iPhone or iPad

struct DeviceType {
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
