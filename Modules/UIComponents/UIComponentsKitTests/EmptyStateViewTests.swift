// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SnapshotTesting
import UIComponentsKit
import XCTest

final class EmptyStateViewTests: XCTestCase {

    func testEmptyStateView() {
        let view = EmptyStateView(
            title: "You Have No Activity",
            subHeading: "All your transactions will show up here.",
            image: ImageAsset.emptyActivity.image
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone8)))
    }
}
