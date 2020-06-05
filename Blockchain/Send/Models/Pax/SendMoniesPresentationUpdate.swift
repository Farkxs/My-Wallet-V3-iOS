//
//  SendMoniesPresentationUpdate.swift
//  Blockchain
//
//  Created by AlexM on 5/30/19.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import PlatformKit
import PlatformUIKit

enum SendMoniesPresentationUpdate: Hashable {
    case cryptoValueTextField(CryptoValue?)
    case fiatValueTextField(FiatValue?)
    case toAddressTextField(String?)
    case feeValueLabel(String?)
    case walletLabel(String?)
    case sendButtonEnabled(Bool)
    case updateNavigationItems
    case textFieldEditingEnabled(Bool)
    case showAlertSheetForError(SendMoniesInternalError)
    case showAlertForEnabling2FA
    case showAlertSheetForSuccess
    case hideConfirmationModal
    case loadingIndicatorVisibility(Visibility)
    case maxAvailable(CryptoValue?)
    case fiatCurrencyLabel(String?)
    case exchangeAddressButtonVisibility(Bool)
    case useExchangeAddress(String?)
}
