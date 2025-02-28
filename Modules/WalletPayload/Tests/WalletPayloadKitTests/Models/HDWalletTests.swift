// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import TestKit
@testable import WalletPayloadKit
import XCTest

// swiftlint:disable line_length
class HDWalletTests: XCTestCase {

    let jsonV3 = Fixtures.loadJSONData(filename: "hdwallet.v3", in: .module)!
    let jsonV4 = Fixtures.loadJSONData(filename: "hdwallet.v4", in: .module)!
    let jsonUnknownAccount = Fixtures.loadJSONData(filename: "hdwallet.unknown", in: .module)!

    func test_it_should_be_able_to_be_decoded_from_json_version4() throws {
        let hdWallet = try JSONDecoder().decode(HDWallet.self, from: jsonV4)

        XCTAssertEqual(hdWallet.seedHex, "6a4d9524d413fdf69ca1b5664d1d6db0")
        XCTAssertEqual(hdWallet.passphrase, "")
        XCTAssertFalse(hdWallet.mnemonicVerified)
        XCTAssertEqual(hdWallet.defaultAccountIndex, 0)

        XCTAssertFalse(hdWallet.accounts.isEmpty)
        let addressCache = AddressCache(
            receiveAccount: "xpub6F41z8MqNcJMvKQgAd5QE2QYo32cocYigWp1D8726ykMmaMqvtqLkvuL1NqGuUJvU3aWyJaV2J4V6sD7Pv59J3tYGZdYRSx8gU7EG8ZuPSY",
            changeAccount: "xpub6F41z8MqNcJMwmeUExdCv7UXvYBEgQB29SWq9jyxuZ7WefmSTWcwXB6NRAJkGCkB3L1Eu4ttzWnPVKZ6REissrQ4i6p8gTi9j5YwDLxmZ8p"
        )
        let derivation = Derivation(
            type: .legacy,
            purpose: Derivation.Format.legacy.purpose,
            xpriv: "xprv9yL1ousLjQQzGNBAYykaT8J3U626NV6zbLYkRv8rvUDpY4f1RnrvAXQneGXC9UNuNvGXX4j6oHBK5KiV2hKevRxY5ntis212oxjEL11ysuG",
            xpub: "xpub6CKNDRQEZmyHUrFdf1HapGEn27ramwpqxZUMEJYUUokoQrz9yLBAiKjGVWDuiCT39udj1r3whqQN89Tar5KrojH8oqSy7ytzJKW8gwmhwD3",
            addressLabels: [AddressLabel(index: 0, label: "labeled_address")],
            cache: addressCache
        )
        let expectedAccount = Account(
            label: "BTC Private Key Wallet",
            archived: false,
            defaultDerivation: Derivation.Format.segwit,
            derivations: [derivation]
        )
        XCTAssertFalse(hdWallet.accounts.isEmpty)
        XCTAssertEqual(hdWallet.accounts.first, expectedAccount)
    }

    func test_it_should_be_able_to_be_decoded_from_json_version3() throws {
        let hdWallet = try JSONDecoder().decode(HDWallet.self, from: jsonV3)

        XCTAssertEqual(hdWallet.seedHex, "6a4d9524d413fdf69ca1b5664d1d6db0")
        XCTAssertEqual(hdWallet.passphrase, "")
        XCTAssertFalse(hdWallet.mnemonicVerified)
        XCTAssertEqual(hdWallet.defaultAccountIndex, 0)

        XCTAssertFalse(hdWallet.accounts.isEmpty)
        let addressCache = AddressCache(
            receiveAccount: "xpub6F41z8MqNcJMvKQgAd5QE2QYo32cocYigWp1D8726ykMmaMqvtqLkvuL1NqGuUJvU3aWyJaV2J4V6sD7Pv59J3tYGZdYRSx8gU7EG8ZuPSY",
            changeAccount: "xpub6F41z8MqNcJMwmeUExdCv7UXvYBEgQB29SWq9jyxuZ7WefmSTWcwXB6NRAJkGCkB3L1Eu4ttzWnPVKZ6REissrQ4i6p8gTi9j5YwDLxmZ8p"
        )
        let derivation = Derivation(
            type: .legacy,
            purpose: Derivation.Format.legacy.purpose,
            xpriv: "xprv9yL1ousLjQQzGNBAYykaT8J3U626NV6zbLYkRv8rvUDpY4f1RnrvAXQneGXC9UNuNvGXX4j6oHBK5KiV2hKevRxY5ntis212oxjEL11ysuG",
            xpub: "xpub6CKNDRQEZmyHUrFdf1HapGEn27ramwpqxZUMEJYUUokoQrz9yLBAiKjGVWDuiCT39udj1r3whqQN89Tar5KrojH8oqSy7ytzJKW8gwmhwD3",
            addressLabels: [AddressLabel(index: 0, label: "labeled_address")],
            cache: addressCache
        )
        let expectedAccount = Account(
            label: "BTC Private Key Wallet",
            archived: false,
            defaultDerivation: .legacy,
            derivations: [derivation]
        )
        XCTAssertFalse(hdWallet.accounts.isEmpty)
        XCTAssertEqual(hdWallet.accounts.first, expectedAccount)
    }

    func test_it_should_throw_an_error_when_decoding_an_unknown_json() throws {
        XCTAssertThrowsError(
            try JSONDecoder().decode(HDWallet.self, from: jsonUnknownAccount)
        )
    }

    func test_it_can_be_encoded_to_json() throws {
        let addressCache = AddressCache(
            receiveAccount: "xpub6F41z8MqNcJMvKQgAd5QE2QYo32cocYigWp1D8726ykMmaMqvtqLkvuL1NqGuUJvU3aWyJaV2J4V6sD7Pv59J3tYGZdYRSx8gU7EG8ZuPSY",
            changeAccount: "xpub6F41z8MqNcJMwmeUExdCv7UXvYBEgQB29SWq9jyxuZ7WefmSTWcwXB6NRAJkGCkB3L1Eu4ttzWnPVKZ6REissrQ4i6p8gTi9j5YwDLxmZ8p"
        )
        let derivation = Derivation(
            type: .legacy,
            purpose: Derivation.Format.legacy.purpose,
            xpriv: "xprv9yL1ousLjQQzGNBAYykaT8J3U626NV6zbLYkRv8rvUDpY4f1RnrvAXQneGXC9UNuNvGXX4j6oHBK5KiV2hKevRxY5ntis212oxjEL11ysuG",
            xpub: "xpub6CKNDRQEZmyHUrFdf1HapGEn27ramwpqxZUMEJYUUokoQrz9yLBAiKjGVWDuiCT39udj1r3whqQN89Tar5KrojH8oqSy7ytzJKW8gwmhwD3",
            addressLabels: [AddressLabel(index: 0, label: "labeled_address")],
            cache: addressCache
        )
        let account = Account(
            label: "BTC Private Key Wallet",
            archived: false,
            defaultDerivation: .legacy,
            derivations: [derivation]
        )

        let encoded = try JSONEncoder().encode(account)
        let decoded = try JSONDecoder().decode(Account.self, from: encoded)

        XCTAssertEqual(decoded, account)
    }
}

// swiftlint:enable line_length
