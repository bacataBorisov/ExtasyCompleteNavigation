//
//  AvailableFontsSwiftUI.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 17.08.23.
//

import SwiftUI

struct AvailableFontsSwiftUI: View {
    
    let allFontNames = UIFont.familyNames
      .flatMap { UIFont.fontNames(forFamilyName: $0) }

    var body: some View {
      List(allFontNames, id: \.self) { name in
        Text(name)
          .font(Font.custom(name, size: 12))
      }
    }
}

struct AvailableFontsSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        AvailableFontsSwiftUI()
    }
}
