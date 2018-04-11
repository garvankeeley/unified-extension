import UIKit
import SnapKit
import MobileCoreServices

protocol ShareViewControllerDelegate: class {
    func finish(afterDelay: TimeInterval)
    func getValidExtensionContext() -> NSExtensionContext?
}

class TopShareViewController: UIViewController {
    var separators = [UIView]()
    var actionRows = [UIView]()
    var stackView: UIStackView!

    weak var delegate: ShareViewControllerDelegate?

    override var extensionContext: NSExtensionContext? {
        get {
            return delegate?.getValidExtensionContext()
        }
    }

    var actions = [UIGestureRecognizer: (() -> Void)]()

    func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = UX.separatorColor
        separators.append(view)
        return view
    }

    func layoutSeparators() {
        separators.forEach {
            $0.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }

    func makePageInfoRow() -> (row: UIView, pageTitleLabel: UILabel, urlLabel: UILabel) {
        let row = UIView()
        //row.layer.borderWidth = 1;row.layer.borderColor = UIColor.blue.cgColor

        let pageTitleLabel = UILabel()
        let urlLabel = UILabel()

        [pageTitleLabel, urlLabel].forEach { label in
            row.addSubview(label)
            label.allowsDefaultTighteningForTruncation = true
            label.lineBreakMode = .byTruncatingMiddle
            label.font = UIFont.systemFont(ofSize: label.font.pointSize - 2)
        }

        pageTitleLabel.font = UIFont.boldSystemFont(ofSize: pageTitleLabel.font.pointSize)
        pageTitleLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(UX.rowInset)
            make.left.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.bottom.equalTo(row.snp.centerY)
        }

        urlLabel.snp.makeConstraints {
            make in
            make.right.equalToSuperview().inset(UX.rowInset)
            make.left.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.top.equalTo(pageTitleLabel.snp.bottom).offset(4)
        }

        return (row, pageTitleLabel, urlLabel)
    }

    func makeActionRow(label: String, imageName: String, action: @escaping (() -> Void), hasNavigation: Bool) -> UIView {
        let row = UIView()
       // row.layer.borderWidth = 1;row.layer.borderColor = UIColor.yellow.cgColor

        let icon = UIImageView(image: UIImage(named: imageName))
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: title.font.pointSize - 2)

        title.text = label
        [icon, title].forEach { row.addSubview($0) }

        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UX.rowInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(34)
        }

        title.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalTo(icon.snp.right).offset(UX.actionRowSpacingForIconAndTitle) 
        }

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure"))
            navButton.contentMode = .scaleAspectFit
            row.addSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(UX.rowInset)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(14)
            }
        }

        let gesture = UITapGestureRecognizer(target: self, action:  #selector(handleRowTapGesture))
        row.addGestureRecognizer(gesture)
        actions[gesture] = action

        actionRows.append(row)
        return row
    }

    @objc fileprivate func handleRowTapGesture(sender: UITapGestureRecognizer) {
        if let action = actions[sender] {
            actions.removeAll() // actions can only be called once
            action()
        }
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.snp.updateConstraints {
            make in
            make.height.equalTo(200)
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.actionRows.forEach { $0.removeFromSuperview() }
            self.separators.forEach { $0.removeFromSuperview() }
            self.navigationController?.view.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.showActionDoneView(withTitle: title)
        })
    }

    @objc func finish(afterDelay: TimeInterval = 0.8) {
        delegate?.finish(afterDelay: afterDelay)
    }

    func showActionDoneView(withTitle title: String) {
        let blue = UIView()
        blue.backgroundColor = UX.doneLabelBackgroundColor
        self.stackView.addArrangedSubview(blue)
        blue.snp.makeConstraints { make in
            make.height.equalTo(UX.pageInfoRowHeight)
        }

        let label = UILabel()
        label.text = title

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 18)

        [label, checkmark].forEach {
            blue.addSubview($0)
            $0.textColor = .white
        }

        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.right.equalTo(checkmark.snp.left)
        }

        checkmark.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(UX.rowInset)
            make.width.equalTo(20)
            //make.width.height.equalTo(22)
        }
    }

    private func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow") // hide separator line
        navigationItem.titleView = UIImageView(image: UIImage(named: "fxLogo"))
        navigationItem.titleView?.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(finish))
    }

    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 4
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupNavBar()
        setupStackView()

        //view.layer.borderColor = UIColor.red.cgColor;view.layer.borderWidth = 1

        let (currentPageInfoRow, pageTitleLabel, urlLabel) = makePageInfoRow()

        let trailing = UIView()

        let rows = [
            currentPageInfoRow,
            makeSeparator(),
            makeActionRow(label: "Open in Firefox Now", imageName:"openInFirefox", action: actionOpenInFirefox, hasNavigation: false),
            makeActionRow(label: "Load in Background", imageName: "menu-Show-Tabs", action: actionLoadInBackground, hasNavigation: false),
            makeActionRow(label: "Bookmark This Page", imageName: "menu-Bookmark", action: actionBookmarkThisPage, hasNavigation: false),
            makeActionRow(label: "Add to Reading List", imageName: "AddToReadingList", action: actionAddToReadingList, hasNavigation: false),
            makeSeparator(),
            makeActionRow(label: "Send to Device", imageName: "menu-Send-to-Device", action: actionSentToDevice, hasNavigation: true),
            trailing
        ]

        rows.forEach {
            stackView.addArrangedSubview($0)
        }

        trailing.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(1)
        }

        layoutSeparators()

        actionRows.forEach {
            $0.snp.makeConstraints { make in
                make.height.equalTo(UX.actionRowHeight)
            }
        }

        currentPageInfoRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(UX.pageInfoRowHeight)
        }

        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = item.attachments?.first as? NSItemProvider, itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
            itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { url, error in
                DispatchQueue.main.sync {
                    urlLabel.text = (url as? URL)?.absoluteString
                    pageTitleLabel.text = item.attributedContentText?.string
                }
            }
        }
        assert(navigationController != nil)
    }
}

class SubVC : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.cyan
        navigationItem.title = "foo"
        navigationItem.backBarButtonItem = nil
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(TopShareViewController.finish))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(TopShareViewController.finish))
    }
}

extension TopShareViewController {

    func actionOpenInFirefox() {
        //animateToActionDoneView(withTitle: "Opening Firefox")
        finish(afterDelay: 0.0)
    }

    func actionLoadInBackground() {
        animateToActionDoneView(withTitle: "Loading in Firefox")

//        let profile = BrowserProfile(localName: "profile")
//        profile.queue.addToQueue(item).uponQueue(.main) { _ in
//            profile.shutdown()
//            context.completeRequest(returningItems: [], completionHandler: nil)
//        }

        finish()
    }

    func actionBookmarkThisPage() {
        animateToActionDoneView(withTitle: "Bookmarked")

//        let profile = BrowserProfile(localName: "profile")
//        _ = profile.bookmarks.shareItem(item).value // Blocks until database has settled
//        profile.shutdown()

        finish()
    }

    func actionAddToReadingList() {
        animateToActionDoneView(withTitle: "Added to Reading List")

//        let profile = BrowserProfile(localName: "profile")
//        profile.readingList.createRecordWithURL(item.url, title: item.title ?? "", addedBy: UIDevice.current.name)
//        profile.shutdown()

        finish()
    }

    func actionSentToDevice() {
        let vc = SubVC(nibName: nil, bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
