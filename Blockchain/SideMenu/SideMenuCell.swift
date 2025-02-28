// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformUIKit

final class SideMenuCell: UITableViewCell {

    fileprivate static let newContainerViewTrailingPadding: CGFloat = 16.0

    /// You must take into account the `peekAmount` of `ECSlidingViewController`
    /// otherwise the `newContainer` will not be visible.
    var peekPadding: CGFloat = 0

    static let defaultHeight: CGFloat = DevicePresenter.type != .superCompact ? 54 : 45

    @IBOutlet var passthroughView: PassthroughView!
    @IBOutlet fileprivate var title: UILabel!
    @IBOutlet fileprivate var icon: UIImageView!
    @IBOutlet fileprivate var newContainerView: UIView!
    @IBOutlet fileprivate var newLabel: UILabel!
    @IBOutlet fileprivate var newContainerTrailingConstraint: NSLayoutConstraint!

    var item: SideMenuItem? {
        didSet {
            title.text = item?.title
            icon.image = item?.image.withRenderingMode(.alwaysTemplate)
            icon.contentMode = .center
            guard let value = item else {
                newContainerView.alpha = 0.0
                return
            }
            newContainerView.alpha = value.isNew ? 1.0 : 0.0
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        title.textColor = #colorLiteral(red: 0.5960784314, green: 0.631372549, blue: 0.6980392157, alpha: 1)
        title.highlightedTextColor = #colorLiteral(red: 0.5960784314, green: 0.631372549, blue: 0.6980392157, alpha: 1)
        title.font = .main(.medium, DevicePresenter.type != .superCompact ? 17 : 14)
        icon.tintColor = #colorLiteral(red: 0.5960784314, green: 0.631372549, blue: 0.6980392157, alpha: 1)
        newContainerView.layer.cornerRadius = 4.0
        newContainerView.backgroundColor = .primaryButton
        newLabel.text = LocalizationConstants.SideMenu.new
        newLabel.font = .main(.medium, DevicePresenter.type != .superCompact ? 15 : 12)
        let padding = SideMenuCell.newContainerViewTrailingPadding
        guard newContainerTrailingConstraint.constant != padding + peekPadding else { return }
        newContainerTrailingConstraint.constant = padding + peekPadding
        setNeedsLayout()
        layoutIfNeeded()
    }
}
