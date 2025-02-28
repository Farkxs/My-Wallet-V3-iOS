// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import SwiftUI
import UIComponentsKit

public struct TradingAccountWarningView: View {

    private typealias LocalizedStrings = LocalizationConstants.FeatureAuthentication.TradingAccountWarning

    private enum Layout {
        static let imageSideLength: CGFloat = 72

        static let messageFontSize: CGFloat = 16
        static let messageLineSpacing: CGFloat = 4
        static let messageBottomPadding: CGFloat = 10

        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24
        static let titleTopPadding: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 10
    }

    public var cancelButtonTapped: (() -> Void)?
    public var logoutButtonTapped: (() -> Void)?

    private let walletIdHint: String

    public init(
        walletIdHint: String
    ) {
        self.walletIdHint = walletIdHint
    }

    public var body: some View {
        VStack {
            Spacer()
            Image.CircleIcon.warning
                .frame(width: Layout.imageSideLength, height: Layout.imageSideLength)
                .accessibility(identifier: AccessibilityIdentifiers.TradingAccountWarningScreen.image)

            Text(LocalizedStrings.title)
                .textStyle(.title)
                .padding(.top, Layout.titleTopPadding)
                .accessibility(identifier: AccessibilityIdentifiers.TradingAccountWarningScreen.title)

            Text(LocalizedStrings.message)
                .font(Font(weight: .medium, size: Layout.messageFontSize))
                .foregroundColor(.textSubheading)
                .lineSpacing(Layout.messageLineSpacing)
                .padding(.bottom, Layout.messageBottomPadding)
                .accessibility(identifier: AccessibilityIdentifiers.TradingAccountWarningScreen.message)

            Text(LocalizedStrings.walletIdMessagePrefix + walletIdHint)
                .font(Font(weight: .medium, size: Layout.messageFontSize))
                .foregroundColor(.textBody)
                .accessibility(identifier: AccessibilityIdentifiers.TradingAccountWarningScreen.walletIdMessagePrefix)
            Spacer()

            PrimaryButton(title: LocalizedStrings.Button.logout) {
                logoutButtonTapped?()
            }
            .padding(.bottom, Layout.buttonBottomPadding)
            .accessibility(identifier: AccessibilityIdentifiers.TradingAccountWarningScreen.logoutButton)

            SecondaryButton(title: LocalizedStrings.Button.cancel) {
                cancelButtonTapped?()
            }
            .accessibility(identifier: AccessibilityIdentifiers.TradingAccountWarningScreen.cancel)
        }
        .multilineTextAlignment(.center)
        .padding(
            EdgeInsets(
                top: 0,
                leading: Layout.leadingPadding,
                bottom: Layout.bottomPadding,
                trailing: Layout.trailingPadding
            )
        )
    }
}

#if DEBUG
struct TradingAccountWarningView_Previews: PreviewProvider {
    static var previews: some View {
        TradingAccountWarningView(
            walletIdHint: ""
        )
    }
}
#endif
