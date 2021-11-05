// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable line_length

import ComposableArchitecture
import NetworkKit
@testable import FeatureOpenBankingDomain
@testable import FeatureOpenBankingUI
import TestKit

final class BankLinkTests: OpenBankingTestCase {

    typealias Store = TestStore<
        BankState,
        BankState,
        BankAction,
        BankAction,
        OpenBankingEnvironment
    >

    private var store: Store!

    // swiftlint:disable:next force_try
    private lazy var update = try! network[
        URLRequest(.post, "https://api.blockchain.info/nabu-gateway/payments/banktransfer/a44d7d14-15f0-4ceb-bf32-bdcb6c6b393c/update")
    ]
    .unwrap()
    .decode(to: OpenBanking.BankAccount.self)

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = .init(
            initialState: initialState,
            reducer: bankReducer,
            environment: environment
        )
    }

    var initialState: BankState {
        .init(data: .init(account: createAccount, action: .link(institution: institution)))
    }

    func test_initial_state() throws {

        let state = initialState
        XCTAssertEqual(state.account, createAccount)
        XCTAssertEqual(state.bankName, "Monzo")
        XCTAssertNil(state.ui)
    }

    func test_request_and_wait_for_approval_with_failure() throws {

        network[
            URLRequest(.get, "https://api.blockchain.info/nabu-gateway/payments/banktransfer/a44d7d14-15f0-4ceb-bf32-bdcb6c6b393c")
        ] = nil

        store.assert(
            .send(.request) { state in
                state.ui = .communicating(to: state.bankName)
            },
            .do { [self] in scheduler.main.advance(by: .seconds(1)) },
            .send(.failure(.timeout)) { state in
                state.ui = .error(.timeout)
            }
        )
    }

    func test_request() throws {

        try store.assert(
            .send(.request) { state in
                state.ui = .communicating(to: state.bankName)
            },
            .receive(.launchAuthorisation(update.attributes.authorisationUrl.unwrap())) { state in
                state.ui = .waiting(for: state.bankName)
            },
            .do { [self] in
                environment.openBanking.state.set(.is.authorised, to: true)
            },
            .receive(.finalise(.linked(createAccount, institution: institution))) { state in
                state.ui = .linked(institution: state.bankName)
            }
        )

        try XCTAssertEqual(openedURL, account.attributes.authorisationUrl.unwrap())
    }

    func test_fail() throws {
        store.assert(
            .send(.failure(.BANK_TRANSFER_ACCOUNT_ALREADY_LINKED)) { state in
                state.ui = .error(.BANK_TRANSFER_ACCOUNT_ALREADY_LINKED)
            }
        )
    }

    func test_dismiss() throws {
        store.send(.dismiss)
        XCTAssertTrue(dismiss)
    }
}

final class BankPaymentTests: OpenBankingTestCase {

    typealias Store = TestStore<
        BankState,
        BankState,
        BankAction,
        BankAction,
        OpenBankingEnvironment
    >

    private var store: Store!

    // swiftlint:disable:next force_try
    private lazy var update = try! network[
        URLRequest(.post, "https://api.blockchain.info/nabu-gateway/payments/banktransfer/a44d7d14-15f0-4ceb-bf32-bdcb6c6b393c/update")
    ]
    .unwrap()
    .decode(to: OpenBanking.BankAccount.self)

    // swiftlint:disable:next force_try
    private lazy var payment = try! network[
        URLRequest(.post, "https://api.blockchain.info/nabu-gateway/payments/banktransfer/a44d7d14-15f0-4ceb-bf32-bdcb6c6b393c/payment")
    ]
    .unwrap()
    .decode(to: OpenBanking.Payment.self)

    // swiftlint:disable:next force_try
    private lazy var details = try! network[
        URLRequest(.get, "https://api.blockchain.info/nabu-gateway/payments/payment/b039317d-df85-413f-932d-2719346a839a")
    ]
    .unwrap()
    .decode(to: OpenBanking.Payment.Details.self)

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = .init(
            initialState: initialState,
            reducer: bankReducer,
            environment: environment
        )
    }

    var initialState: BankState {
        .init(data: .init(account: createAccount, action: .deposit(amountMinor: "1000", product: "SIMPLEBUY")))
    }

    func test_initial_state() throws {
        let state = initialState
        XCTAssertEqual(state.account, createAccount)
        XCTAssertEqual(state.bankName, "Your Bank")
        XCTAssertNil(state.ui)
    }

    func test_request() throws {

        try store.assert(
            .send(.request) { state in
                state.ui = .communicating(to: state.bankName)
            },
            .receive(.launchAuthorisation(update.attributes.authorisationUrl.unwrap())) { state in
                state.ui = .waiting(for: state.bankName)
            },
            .do { [self] in
                environment.openBanking.state.set(.is.authorised, to: true)
            },
            .receive(.finalise(.deposited(details))) { [self] state in
                state.ui = .payment(success: details, in: environment)
            }
        )

        try XCTAssertEqual(openedURL, account.attributes.authorisationUrl.unwrap())
    }
}
