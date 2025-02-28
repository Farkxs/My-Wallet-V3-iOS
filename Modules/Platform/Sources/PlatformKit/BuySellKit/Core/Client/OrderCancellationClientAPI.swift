// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NabuNetworkError

protocol OrderCancellationClientAPI: AnyObject {

    /// Cancels an order with a given identifier
    func cancel(
        order id: String
    ) -> AnyPublisher<Void, NabuNetworkError>
}
