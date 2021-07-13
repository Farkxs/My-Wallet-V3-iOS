// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import PlatformKit
import RxCocoa
import RxSwift
import ToolKit

final class NonCustodialActionScreenPresenter: WalletActionScreenPresenting {

    // MARK: - Types

    typealias AccessibilityId = Accessibility.Identifier.WalletActionSheet
    typealias LocalizationIds = LocalizationConstants.DashboardDetails
    typealias CellType = WalletActionCellType

    // MARK: - Public Properties

    var sections: Observable<[WalletActionItemsSectionViewModel]> {
        sectionsRelay
            .asObservable()
    }

    let selectionRelay: PublishRelay<WalletActionCellType> = .init()

    let assetBalanceViewPresenter: CurrentBalanceCellPresenter

    var currency: CurrencyType {
        interactor.currency
    }

    // MARK: - Private Properties

    private let sectionsRelay = BehaviorRelay<[WalletActionItemsSectionViewModel]>(value: [])
    private let interactor: WalletActionScreenInteracting
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(using interactor: WalletActionScreenInteracting,
         stateService: NonCustodialActionStateServiceAPI,
         featureConfigurator: FeatureConfiguring = resolve(),
         analyticsRecorder: AnalyticsEventRecorderAPI = resolve()) {
        self.interactor = interactor
        self.analyticsRecorder = analyticsRecorder
        let currency = interactor.currency
        let descriptionValue: () -> Observable<String> = {
            .just(currency.name)
        }

        assetBalanceViewPresenter = CurrentBalanceCellPresenter(
            interactor: interactor.balanceCellInteractor,
            descriptionValue: descriptionValue,
            currency:  interactor.currency,
            titleAccessibilitySuffix: "\(Accessibility.Identifier.DashboardDetails.CurrentBalanceCell.titleValue)",
            descriptionAccessibilitySuffix: "\(Accessibility.Identifier.DashboardDetails.CurrentBalanceCell.descriptionValue)",
            pendingAccessibilitySuffix: "\(Accessibility.Identifier.DashboardDetails.CurrentBalanceCell.pendingValue)",
            descriptors: .default(
                cryptoAccessiblitySuffix: "\(AccessibilityId.NonCustodial.cryptoValue)",
                fiatAccessiblitySuffix: "\(AccessibilityId.NonCustodial.fiatValue)"
            )
        )

        var actionCells: [WalletActionCellType] = [.balance(assetBalanceViewPresenter)]

        guard case let .crypto(crypto) = currency else { return }
        var actionPresenters: [DefaultWalletActionCellPresenter] = []

        if crypto.hasNonCustodialSupport {
            actionPresenters.append(
                .init(currencyType: currency, action: .send)
            )
        }

        if crypto.hasNonCustodialReceiveSupport {
            actionPresenters.append(
                .init(currencyType: currency, action: .receive)
            )
        }

        if crypto.hasSwapSupport {
            actionPresenters.append(
                .init(currencyType: currency, action: .swap)
            )
        }

        if crypto.hasNonCustodialSupport {
            actionPresenters.append(
                .init(currencyType: currency, action: .activity)
            )
        }

        actionCells.append(contentsOf: actionPresenters.map { .default($0) })
        sectionsRelay.accept([.init(items: actionCells)])

        selectionRelay
            .bind { model in
                guard case let .default(presenter) = model else { return }
                switch presenter.action {
                case .activity:
                    stateService.selectionRelay.accept(.next(.activity))
                case .swap:
                    stateService.selectionRelay.accept(.next(.swap))
                    analyticsRecorder.record(event: AnalyticsEvents.New.Swap.swapClicked(origin: .currencyPage))
                case .send:
                    stateService.selectionRelay.accept(.next(.send))
                case .receive:
                    stateService.selectionRelay.accept(.next(.receive))
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
    }
}
