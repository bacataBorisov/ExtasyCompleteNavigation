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

/// Presentation for content pushed inside navigation (e.g. settings).
public enum RoundedBackgroundChrome: Sendable {
    /// Inset “card” with shadow — fine for static panels; can fight `List` / `NavigationLink` width on iPad.
    case card
    /// Edge-to-edge background; content gets full width so pushed settings tabs don’t hit 0‑pt layout slots.
    case fullBleed
}

public struct RoundedBackgroundView<Content: View>: View {
    let content: Content
    let chrome: RoundedBackgroundChrome
    private let sectionPadding: CGFloat = 8

    public init(chrome: RoundedBackgroundChrome = .fullBleed, @ViewBuilder content: () -> Content) {
        self.chrome = chrome
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            switch chrome {
            case .card:
                content
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(sectionPadding)
            case .fullBleed:
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 1, minHeight: 1)
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
