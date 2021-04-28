//
//  SwapRootInteractor.swift
//  TransactionUIKit
//
//  Created by Paulo on 29/09/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import AnalyticsKit
import DIKit
import KYCUIKit
import PlatformKit
import PlatformUIKit
import RIBs
import RxSwift
import ToolKit

protocol SwapRootListener: ViewListener { }

final class SwapRootInteractor: Interactor, SwapBootstrapListener, SwapRootListener, SwapLandingListener, TransactionFlowListener {

    typealias AnalyticsEvent = AnalyticsEvents.Swap

    private let kycTiersPageModelFactory: KYCTiersPageModelFactoryAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    weak var router: SwapRootRouting?

    init(kycTiersPageModelFactory: KYCTiersPageModelFactoryAPI = resolve(),
         analyticsRecorder: AnalyticsEventRecorderAPI = resolve()) {
        self.kycTiersPageModelFactory = kycTiersPageModelFactory
        self.analyticsRecorder = analyticsRecorder
        super.init()
    }

    func userMustKYCForSwap() {
        analyticsRecorder.record(event: AnalyticsEvent.verifyNowClicked)
        router?.routeToKYC()
    }
    
    func userReadyForSwap() {
        router?.routeToSwapLanding()
    }

    func userMustCompleteKYC(model: KYCTiersPageModel) {
        router?.routeToSwapTiers(model: model, present: false)
    }

    func presentKYCTiersScreen() {
        kycTiersPageModelFactory
            .tiersPageModel(suppressCTA: true)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe { [weak router] model in
                router?.routeToSwapTiers(model: model, present: true)
            }
            .disposeOnDeactivate(interactor: self)
    }
    
    func dismissTransactionFlow() {
        router?.dismissTransactionFlow()
    }

    func routeToSwap(with pair: SwapTrendingPair?) {
        router?.routeToSwap(with: pair)
    }

    private lazy var routeViewDidAppear: Void = {
        router?.routeToSwapBootstrap()
    }()
    
    func viewDidAppear() {
        // if first time, got to variant router
        _ = routeViewDidAppear
    }
}
