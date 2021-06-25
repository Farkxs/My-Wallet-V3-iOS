// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// Interface for unique guid provider. This id is used to identify anonymous user.
public protocol GuidProviderAPI {
    var guid: String? { get }
}
