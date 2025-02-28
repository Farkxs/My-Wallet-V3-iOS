// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import PlatformUIKit
import SafariServices

extension UIApplication {

    // MARK: - Open the AppStore at the app's page

    @objc public func openAppStore() {
        let url = URL(string: "\(Constants.Url.appStoreLinkPrefix)\(Constants.AppStore.AppID)")!
        open(url)
    }
}
