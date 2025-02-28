// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable line_length

import ComposableArchitecture
@testable import FeatureOpenBankingUI
import NetworkKit
import TestKit
import ToolKit

class OpenBankingTestCase: XCTestCase {

    private(set) var scheduler = DispatchQueue.test

    private(set) var showTransferDetails: Bool = false
    private(set) var dismiss: Bool = false
    private(set) var openedURL: URL?

    private(set) var environment: OpenBankingEnvironment!
    private(set) var network: ReplayNetworkCommunicator!
    var state: OpenBanking.State {
        environment.openBanking.state
    }

    // swiftlint:disable:next force_try
    lazy var createAccount = try! network[
        URLRequest(.post, "https://api.blockchain.info/nabu-gateway/payments/banktransfer")
    ]
    .unwrap()
    .decode(to: OpenBanking.BankAccount.self)

    // swiftlint:disable:next force_try
    lazy var account = try! network[
        URLRequest(.get, "https://api.blockchain.info/nabu-gateway/payments/banktransfer/a44d7d14-15f0-4ceb-bf32-bdcb6c6b393c")
    ]
    .unwrap()
    .decode(to: OpenBanking.BankAccount.self)

    lazy var institution = createAccount.attributes.institutions![1]

    override func setUpWithError() throws {
        try super.setUpWithError()
        scheduler = DispatchQueue.test
        (environment, network) = OpenBankingEnvironment.test(
            scheduler: scheduler.eraseToAnyScheduler(),
            showTransferDetails: { [self] in showTransferDetails = true },
            dismiss: { [self] in dismiss = true },
            openURL: { [self] in openedURL = $0 }
        )
    }
}

extension TestStore where LocalState: Equatable, Action: Equatable {

    /// Asserts against a script of actions.
    public func assert(
        _ first: [Step],
        _ rest: Step...,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assert(first + rest, file: file, line: line)
    }
}

struct OpenURL: URLOpener {

    var yield: (URL) -> Void

    func open(_ url: URL, completionHandler: @escaping (Bool) -> Void) {
        yield(url)
        completionHandler(true)
    }
}
