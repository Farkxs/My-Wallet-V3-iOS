// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import RxSwift
import ToolKit

final class BuyTransactionEngine: TransactionEngine {

    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!
    let requireSecondPassword: Bool = false
    let canTransactFiat: Bool = true

    private let priceService: PriceServiceAPI

    init(priceService: PriceServiceAPI = resolve()) {
        self.priceService = priceService
    }

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        transactionExchangeRatePair
            .map { quote in
                TransactionMoneyValuePairs(
                    source: quote,
                    destination: quote.inverseExchangeRate
                )
            }
    }

    var transactionExchangeRatePair: Observable<MoneyValuePair> {
        fetchExchangeRate(from: transactionTarget.currencyType, to: sourceAccount.currencyType)
            .share(replay: 1, scope: .whileConnected)
    }

    var askForRefreshConfirmation: (AskForRefreshConfirmation)! // TODO: use this

    func assertInputsValid() {
        assert(sourceAccount is FeatureTransactionDomain.PaymentMethodAccount)
        assert(transactionTarget is CryptoAccount)
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        makeTransaction()
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        makeTransaction(amount: amount)
    }

    func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        var transaction = pendingTransaction
        do {
            if try transaction.amount > transaction.maxSpendable {
                transaction.validationState = .overMaximumLimit
            } else if try transaction.amount < transaction.minimumLimit ?? .zero(currency: sourceAccount.currencyType) {
                transaction.validationState = .belowMinimumLimit
            } else {
                transaction.validationState = .canExecute
            }
            return .just(transaction)
        } catch {
            return .error(error)
        }
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        // TODO: implement me
        .just(pendingTransaction)
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        transactionExchangeRatePair.asSingle()
            .flatMap { [sourceAccount] moneyPair in

                let cryptoValue = try pendingTransaction.amount.convert(
                    using: moneyPair.inverseExchangeRate.quote
                ).cryptoValue!

                var confirmations: [TransactionConfirmation] = [
                    .buyCryptoValue(.init(baseValue: cryptoValue)),
                    .buyExchangeRateValue(.init(baseValue: moneyPair.quote, code: moneyPair.base.code)),
                    .buyPaymentMethod(.init(name: sourceAccount?.label ?? "")),
                    .transactionFee(.init(fee: pendingTransaction.feeAmount)),
                    .total(.init(total: try pendingTransaction.amount + pendingTransaction.feeAmount))
                ]
                if let customFeeAmount = pendingTransaction.customFeeAmount {
                    confirmations.append(.transactionFee(.init(fee: customFeeAmount)))
                }
                return Single.just(pendingTransaction.update(confirmations: confirmations))
            }
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        unimplemented() // TODO: implement me
    }

    func doPostExecute(transactionResult: TransactionResult) -> Completable {
        unimplemented() // TODO: implement me
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        impossible("Fees are fixed for buying crypto")
    }

    // MARK: - Helpers

    private func makeTransaction(amount: MoneyValue? = nil) -> Single<PendingTransaction> {
        guard let paymentAccount = sourceAccount as? FeatureTransactionDomain.PaymentMethodAccount,
              let fiatCurrency = paymentAccount.currencyType.fiatCurrency
        else {
            return .error(TransactionValidationFailure(state: .optionInvalid))
        }
        let amount = amount ?? .zero(currency: fiatCurrency)
        let paymentMethod = paymentAccount.paymentMethod
        return Single.zip(
            sourceAccount.balance,
            fiatExchangeRatePairs.asSingle()
        )
        .map { sourceBalance, exchangePairs in
            let targetToSourceExchangeRate = exchangePairs.source
            return PendingTransaction(
                amount: try amount.convert(using: targetToSourceExchangeRate),
                available: sourceBalance,
                feeAmount: .zero(currency: fiatCurrency), // TODO: calculate the fee properly
                feeForFullAvailable: .zero(currency: fiatCurrency), // TODO: calculate the fee properly
                feeSelection: .empty(asset: paymentAccount.currencyType), // TODO: does this need adjusting to support a payment fee?
                selectedFiatCurrency: fiatCurrency,
                minimumLimit: paymentMethod.min.moneyValue,
                maximumLimit: paymentMethod.max.moneyValue,
                maximumDailyLimit: paymentMethod.maxDaily.moneyValue,
                maximumAnnualLimit: paymentMethod.maxAnnual.moneyValue
            )
        }
        .flatMap(weak: self) { (self, transaction) in
            self.validateAmount(pendingTransaction: transaction)
        }
    }

    private func fetchExchangeRate(from source: CurrencyType, to target: CurrencyType) -> Observable<MoneyValuePair> {
        priceService.price(of: source, in: target)
            .asObservable()
            .map(\.moneyValue)
            .map { quote in
                MoneyValuePair(base: .one(currency: source), quote: quote)
            }
    }
}
