//  WHAT: The mark as a SwiftUI view: one file declaring the type a call names (`SeerMark`), which draws the catalog's
//        `LogoMark` resizable and scaled to fit, so it fills whatever frame it is given, and hides it from VoiceOver
//        (the screen around the mark names the app).
//  PIN:  THE MARK AND NOTHING ELSE. No size, no shadow, no rotation, no animation: the kits that place the mark add
//        those, and a view that brought its own would fight them.
//  PIN:  SWIFT 5 AND SWIFT 6, iOS AND macOS. Only what both language modes and every platform since iOS 14 and
//        macOS 11 read.

import Foundation

enum MarkView {
    /// The file declaring `name`.
    static func source(name: String) -> String {
        """
        import SwiftUI

        /// The app's mark: the LogoMark image from the asset catalog, scaled to fit whatever frame it is given.
        struct \(name): View {
            var body: some View {
                Image("LogoMark")
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            }
        }

        """
    }
}
