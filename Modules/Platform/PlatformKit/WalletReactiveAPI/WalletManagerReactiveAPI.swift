// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import CombineExt

public protocol WalletManagerReactiveAPI {

    // MARK: WalletAuthDelegate
    
    /// Reactive wrapper for delegate method `walletDidDecrypt(withSharedKey:guid:)`
    /// - Note: Returns a `WalletDecryption` instance containing info as received from the delegate method
    var didDecryptWallet: AnyPublisher<WalletDecryption, Error> { get }

    /// Reactive wrapper for authentication delegate methods
    /// - Note: The following methods will be taken into account and will create a `Result<Bool, AuthenticationError>`:
    /// - `walletDidFinishLoad`
    /// - `walletFailedToLoad`
    /// - `walletFailedToDecrypt`
    var didCompleteAuthentication: AnyPublisher<Result<Bool, AuthenticationError>, Never> { get }

    // MARK: WalletAccountInfoDelegate

    /// Reactive wrapper for delegate method `walletDidGetAccountInfo`
    /// - Note: Invoked when the account info has been retrieved
    var didGetAccountInfo: AnyPublisher<Void, Error> { get }

    // MARK: WalletAddressesDelegate

    /// Reactive wrapper for delegate method `didGenerateNewAddress`
    /// - Note: Method invoked when generating a new address (V2/legacy wallet only)
    var newAddressGenerated: AnyPublisher<Void, Error> { get }

    /// Reactive wrapper for delegate method `returnToAddressesScreen`
    /// - Note: Method invoked when finding a null account or address when checking if archived
    var shouldReturnToAddressesScreen: AnyPublisher<Void, Error> { get }

    /// Reactive wrapper for delegate method `didSetDefaultAccount`
    /// - Note: Method invoked when the default account for an asset has been changed
    var defaultAccountSet: AnyPublisher<Void, Error> { get }

    // MARK: WalletRecoveryDelegate

    /// Reactive wrapper for delegate method `didRecoverWallet`
    /// - Note:  Method invoked when the recovery sequence is completed
    var walletRecovered: AnyPublisher<Void, Error> { get }

    /// Reactive wrapper for delegate method `didFailRecovery`
    /// - Note:  Method invoked when the recovery sequence fails to complete
    var walletRecoveryFailed: AnyPublisher<Void, Error> { get }

    // MARK: WalletHistoryDelegate

    /// Reactive wrapper for delegate method `didFailGetHistory`
    /// - Note:  Method invoked when the recovery sequence fails to complete
    var walletFailedToGetHistory: AnyPublisher<String?, Error> { get }

    // MARK: WalletAccountInfoAndExchangeRatesDelegate

    /// Reactive wrapper for delegate method `walletDidGetAccountInfoAndExchangeRates`
    /// - Note: Method invoked after getting account info and exchange rates on startup
    var walletDidGetAccountInfoAndExchangeRates: AnyPublisher<Void, Error> { get }

    // MARK: WalletBackupDelegate

    /// Reactive wrapper for delegate method `didBackupWallet`
    /// - Note: Method invoked when backup sequence is completed
    var walletBackupSuccess: AnyPublisher<Void, Error> { get }

    /// Reactive wrapper for delegate method `didFailBackupWallet`
    /// - Note: Method invoked when backup sequence is completed
    var walletBackupFailed: AnyPublisher<Void, Error> { get }

    // MARK: WalletSecondPasswordDelegate

    /// Reactive wrapper for delegate method `getSecondPassword`
    /// - Note: Method invoked when second password is required for JS function to complete.
    var getSecondPassword: AnyPublisher<(success: WalletSuccessCallback, dismiss: WalletDismissCallback?), Error> { get }

    /// Reactive wrapper for delegate method `getPrivateKeyPassword`
    /// - Note: Method invoked when second password is required for JS function to complete.
    var getPrivateKeyPassword: AnyPublisher<WalletSuccessCallback, Error> { get }

}
