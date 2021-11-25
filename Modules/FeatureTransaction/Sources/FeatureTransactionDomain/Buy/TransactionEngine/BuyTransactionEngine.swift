// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import PlatformKit
import RxSwift
import ToolKit

extension OrderDetails: TransactionOrder {}

final class BuyTransactionEngine: TransactionEngine {

    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!
    let requireSecondPassword: Bool = false
    let canTransactFiat: Bool = true

    // Used to convert fiat <-> crypto when user types an amount (mainly crypto -> fiat)
    let currencyConversionService: CurrencyConversionServiceAPI
    // Used to convert payment method currencies into the wallet's default currency
    let walletCurrencyService: FiatCurrencyServiceAPI

    // Used to convert the user input into an actual quote with fee (takes a fiat amount)
    private let orderQuoteService: OrderQuoteServiceAPI
    // Used to create a pending order when the user confirms the transaction
    private let orderCreationService: OrderCreationServiceAPI
    // Used to execute the order once created
    private let orderConfirmationService: OrderConfirmationServiceAPI
    // Used to cancel orders
    private let orderCancellationService: OrderCancellationServiceAPI
    // Used to fetch limits for the transaction
    private let transactionLimitsService: TransactionLimitsServiceAPI

    // Used as a workaround to show the correct total fee to the user during checkout.
    // This won't be needed anymore once we migrate the quotes API to v2
    private var pendingCheckoutData: CheckoutData?

    init(
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        orderQuoteService: OrderQuoteServiceAPI = resolve(),
        orderCreationService: OrderCreationServiceAPI = resolve(),
        orderConfirmationService: OrderConfirmationServiceAPI = resolve(),
        orderCancellationService: OrderCancellationServiceAPI = resolve(),
        transactionLimitsService: TransactionLimitsServiceAPI = resolve()
    ) {
        self.currencyConversionService = currencyConversionService
        self.walletCurrencyService = walletCurrencyService
        self.orderQuoteService = orderQuoteService
        self.orderCreationService = orderCreationService
        self.orderConfirmationService = orderConfirmationService
        self.orderCancellationService = orderCancellationService
        self.transactionLimitsService = transactionLimitsService
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

    var fiatExchangeRatePairsSingle: Single<TransactionMoneyValuePairs> {
        fiatExchangeRatePairs
            .take(1)
            .asSingle()
    }

    var transactionExchangeRatePair: Observable<MoneyValuePair> {
        let cryptoCurrency = transactionTarget.currencyType
        return walletCurrencyService
            .fiatCurrencyObservable
            .map(\.currencyType)
            .flatMap { [currencyConversionService] walletCurrency in
                currencyConversionService
                    .conversionRate(from: cryptoCurrency, to: walletCurrency)
                    .map { quote in
                        MoneyValuePair(
                            base: .one(currency: cryptoCurrency),
                            quote: quote
                        )
                    }
                    .asObservable()
            }
            .share(replay: 1, scope: .whileConnected)
    }

    // Unused but required by `TransactionEngine` protocol
    var askForRefreshConfirmation: AskForRefreshConfirmation!

    func assertInputsValid() {
        assert(sourceAccount is PaymentMethodAccount)
        assert(transactionTarget is CryptoAccount)
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        makeTransaction()
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        makeTransaction(amount: amount)
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmount(pendingTransaction: pendingTransaction)
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        let sourceAccountLabel = sourceAccount.label
        let orderFuture = createOrder(pendingTransaction: pendingTransaction)
            .map { order -> OrderDetails in
                guard let order = order as? OrderDetails else {
                    impossible("Buy transactions should only create \(OrderDetails.self) orders")
                }
                return order
            }
        return Single.zip(orderFuture, fiatExchangeRatePairsSingle)
            .map { order, moneyPair in
                let fiatAmount: FiatValue
                let cryptoAmount: CryptoValue

                // Ideally, we should use the value in the created order, since we have one
                if let input = order.inputValue.fiatValue, let output = order.outputValue.cryptoValue {
                    fiatAmount = input
                    cryptoAmount = output
                } else {
                    // as a fallback... and probably after there's no longer a need to create an order to get the correct fees...
                    if pendingTransaction.amount.isFiat {
                        fiatAmount = pendingTransaction.amount.fiatValue!
                        cryptoAmount = try pendingTransaction.amount
                            .convert(using: moneyPair.destination)
                            .cryptoValue!
                    } else {
                        fiatAmount = try pendingTransaction.amount
                            .convert(using: moneyPair.source)
                            .fiatValue!
                        cryptoAmount = pendingTransaction.amount.cryptoValue!
                    }
                }

                let totalCost = order.inputValue
                let fee = order.fee ?? .zero(currency: fiatAmount.currency)

                var confirmations: [TransactionConfirmation] = [
                    .buyCryptoValue(.init(baseValue: cryptoAmount)),
                    .buyExchangeRateValue(.init(baseValue: moneyPair.source.quote, code: moneyPair.source.base.code)),
                    .buyPaymentMethod(.init(name: sourceAccountLabel)),
                    .transactionFee(.init(fee: fee))
                ]

                if let customFeeAmount = pendingTransaction.customFeeAmount {
                    confirmations.append(.transactionFee(.init(fee: customFeeAmount)))
                }

                confirmations.append(.total(.init(total: totalCost)))

                return pendingTransaction.update(confirmations: confirmations)
            }
    }

    func createOrder(pendingTransaction: PendingTransaction) -> Single<TransactionOrder?> {
        guard pendingCheckoutData == nil else {
            return .just(pendingCheckoutData?.order)
        }
        guard let sourceAccount = sourceAccount as? PaymentMethodAccount else {
            return .error(TransactionValidationFailure(state: .optionInvalid))
        }
        // STEP 1: Get a fresh quote for the transaction
        return fetchQuote(for: pendingTransaction.amount)
            // STEP 2: Create an Order for the transaction
            .flatMap { [orderCreationService] refreshedQuote -> Single<CheckoutData> in
                let paymentMethodId: String?
                if sourceAccount.paymentMethod.type.isFunds {
                    // NOTE: This fixes IOS-5389
                    paymentMethodId = nil
                } else {
                    paymentMethodId = sourceAccount.paymentMethodType.id
                }
                let orderDetails = CandidateOrderDetails.buy(
                    paymentMethod: sourceAccount.paymentMethodType,
                    fiatValue: refreshedQuote.estimatedFiatAmount,
                    cryptoValue: refreshedQuote.estimatedCryptoAmount,
                    paymentMethodId: paymentMethodId
                )
                return orderCreationService.create(using: orderDetails)
            }
            .do(onSuccess: { [weak self] checkoutData in
                Logger.shared.info("[BUY] Order creation successful \(String(describing: checkoutData))")
                self?.pendingCheckoutData = checkoutData
            }, onError: { error in
                Logger.shared.error("[BUY] Order creation failed \(String(describing: error))")
            })
            .map(\.order)
            .map(Optional.some)
    }

    func cancelOrder(with identifier: String) -> Single<Void> {
        orderCancellationService.cancelOrder(with: identifier)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.pendingCheckoutData = nil
            }, receiveCompletion: { [weak self] completion in
                guard case .finished = completion else {
                    return
                }
                self?.pendingCheckoutData = nil
            })
            .asSingle()
    }

    func execute(
        pendingTransaction: PendingTransaction,
        pendingOrder: TransactionOrder?,
        secondPassword: String
    ) -> Single<TransactionResult> {
        guard let order = pendingOrder as? OrderDetails else {
            return .error(TransactionValidationFailure(state: .optionInvalid))
        }
        // Execute the order
        return orderConfirmationService.confirm(checkoutData: CheckoutData(order: order))
            // Map order to Transaction Result
            .map { checkoutData -> TransactionResult in
                TransactionResult.hashed(
                    txHash: checkoutData.order.identifier,
                    amount: pendingTransaction.amount,
                    order: checkoutData.order
                )
            }
            .do(onSuccess: { [weak self] checkoutData in
                Logger.shared.info("[BUY] Order confirmation successful \(String(describing: checkoutData))")
                self?.pendingCheckoutData = nil
            }, onError: { error in
                Logger.shared.error("[BUY] Order confirmation failed \(String(describing: error))")
            })
    }

    func doPostExecute(transactionResult: TransactionResult) -> Completable {
        transactionTarget.onTxCompleted(transactionResult)
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        impossible("Fees are fixed for buying crypto")
    }
}

// MARK: - Helpers

extension BuyTransactionEngine {

    enum MakeTransactionError: Error {
        case priceError(PriceServiceError)
        case limitsError(TransactionLimitsServiceError)
    }

    private func makeTransaction(amount: MoneyValue? = nil) -> Single<PendingTransaction> {
        guard let sourceAccount = sourceAccount as? PaymentMethodAccount else {
            return .error(TransactionValidationFailure(state: .optionInvalid))
        }
        let paymentMethod = sourceAccount.paymentMethod
        let amount = amount ?? .zero(currency: paymentMethod.fiatCurrency.currencyType)
        return Publishers.Zip(
            convertSourceBalance(to: amount.currencyType),
            transactionLimits(for: paymentMethod, inputCurrency: amount.currencyType)
        )
        .tryMap { sourceBalance, limits in
            // NOTE: the fee coming from the API is always 0 at the moment.
            // The correct fee will be fetched when the order is created.
            // This misleading behavior doesn't affect the purchase.
            // That said, this is going to be fixed once we migrate to v2 of the quotes API.
            let zeroFee: MoneyValue = .zero(currency: amount.currency)
            return PendingTransaction(
                amount: amount,
                available: sourceBalance,
                feeAmount: zeroFee,
                feeForFullAvailable: zeroFee,
                feeSelection: .empty(asset: amount.currencyType),
                selectedFiatCurrency: sourceAccount.fiatCurrency,
                limits: limits
            )
        }
        .asSingle()
    }

    private func fetchQuote(for amount: MoneyValue) -> Single<Quote> {
        guard let source = sourceAccount as? FiatAccount else {
            return .error(TransactionValidationFailure(state: .uninitialized))
        }
        guard let destination = transactionTarget as? CryptoAccount else {
            return .error(TransactionValidationFailure(state: .uninitialized))
        }
        return convertAmountIntoWalletFiatCurrency(amount)
            .flatMap { [orderQuoteService] fiatValue in
                orderQuoteService.getQuote(
                    for: .simpleBuy,
                    from: source.fiatCurrency,
                    to: destination.asset,
                    amount: fiatValue,
                    paymentMethod: nil,
                    paymentMethodId: nil
                )
            }
    }

    private func convertAmountIntoWalletFiatCurrency(_ amount: MoneyValue) -> Single<FiatValue> {
        fiatExchangeRatePairsSingle
            .map { moneyPair in
                guard !amount.isFiat else {
                    return amount.fiatValue!
                }
                return try amount
                    .convert(using: moneyPair.source)
                    .fiatValue!
            }
    }

    private func convertSourceBalance(to currency: CurrencyType) -> AnyPublisher<MoneyValue, MakeTransactionError> {
        sourceAccount
            .balance
            .asPublisher()
            .replaceError(with: .zero(currency: currency))
            .flatMap { [currencyConversionService] balance in
                currencyConversionService.convert(balance, to: currency)
            }
            .mapError(MakeTransactionError.priceError)
            .eraseToAnyPublisher()
    }

    private func transactionLimits(
        for paymentMethod: PaymentMethod,
        inputCurrency: CurrencyType
    ) -> AnyPublisher<TransactionLimits, MakeTransactionError> {
        transactionLimitsService
            .fetchLimits(
                for: paymentMethod,
                targetCurrency: transactionTarget.currencyType,
                limitsCurrency: inputCurrency,
                product: .simplebuy
            )
            .mapError(MakeTransactionError.limitsError)
            .eraseToAnyPublisher()
    }
}
