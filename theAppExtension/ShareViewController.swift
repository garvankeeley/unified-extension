import UIKit
import Social
import SnapKit
import MobileCoreServices

fileprivate let topViewHeight = 365
fileprivate let topViewWidth = 345
fileprivate let pageInfoRowHeight = 64
fileprivate let pageInfoRowLeftInset = 16
fileprivate let actionRowHeight = 44
fileprivate let rowInset = 8
fileprivate var heightConstraint: Constraint!

fileprivate weak var topLevelViewController: UIViewController?

class EmbeddedNavController {
    weak var parent: UIViewController?
    var controllers = [UIViewController]()
    var navigationController: UINavigationController

    init (parent: UIViewController, rootViewController: UIViewController) {
        self.parent = parent
        navigationController = UINavigationController(rootViewController: rootViewController)

        parent.addChildViewController(navigationController)
        parent.view.addSubview(navigationController.view)

        let width = min(UIScreen.main.bounds.width, CGFloat(topViewWidth))

        navigationController.view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(width)
            heightConstraint = make.height.equalTo(topViewHeight).constraint
        }

        navigationController.view.layer.cornerRadius = 8
        navigationController.view.layer.masksToBounds = true
    }

    deinit {
        navigationController.view.removeFromSuperview()
        navigationController.removeFromParentViewController()
    }
}

class ShareViewController: UIViewController {
    var embedController: EmbeddedNavController!

    override func viewDidLoad() {
        topLevelViewController = self
        assert(extensionContext != nil)

        super.viewDidLoad()
        let firstPage = ShareGeneralViewController()
        embedController = EmbeddedNavController(parent: self, rootViewController: firstPage)

        view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
    }
}

class ShareGeneralViewController: UIViewController {
    var separators = [UIView]()
    var actionRows = [UIView]()
    var stackView: UIStackView!

    var actions = [UIGestureRecognizer: (() -> Void)]()

    func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: CGFloat(205.0/255.0), alpha: 1.0)
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
            make.right.equalToSuperview().inset(rowInset)
            make.left.equalToSuperview().inset(pageInfoRowLeftInset)
            make.bottom.equalTo(row.snp.centerY)
        }

        urlLabel.snp.makeConstraints {
            make in
            make.right.equalToSuperview().inset(rowInset)
            make.left.equalToSuperview().inset(pageInfoRowLeftInset)
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
            make.left.equalToSuperview().inset(rowInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(34)
        }

        title.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalTo(icon.snp.right).offset(8) // space between title and icon
        }

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure"))
            navButton.contentMode = .scaleAspectFit
            row.addSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(rowInset)
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

        heightConstraint.update(offset: 200)

        UIView.animate(withDuration: 0.2, animations: {
            self.actionRows.forEach { $0.removeFromSuperview() }
            self.separators.forEach { $0.removeFromSuperview() }
            self.navigationController?.view.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.showActionDoneView(withTitle: title)
        })
    }

    @objc func cancel() {
       hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
        topLevelViewController?.extensionContext?.cancelRequest(withError: NSError(domain: "cancel", code: 0, userInfo: nil))
       })
    }

    func showActionDoneView(withTitle title: String) {
        let blue = UIView()
        blue.backgroundColor = UIColor(red: 76 / 255.0, green: 158 / 255.0, blue: 1.0, alpha: 1.0)
        self.stackView.addArrangedSubview(blue)
        blue.snp.makeConstraints { make in
            make.height.equalTo(pageInfoRowHeight)
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
            make.left.equalToSuperview().inset(pageInfoRowLeftInset)
            make.right.equalTo(checkmark.snp.left)
        }

        checkmark.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(rowInset)
            make.width.equalTo(20)
            //make.width.height.equalTo(22)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.cancel()
        }
    }

    func hideExtensionWithCompletionHandler(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [], animations: {
            topLevelViewController?.view.alpha = 0
        }, completion: { (finished: Bool) in
            completion(finished)
        })
    }

    private func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow") // hide separator line
        navigationItem.titleView = UIImageView(image: UIImage(named: "fxLogo"))
        navigationItem.titleView?.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
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
                make.height.equalTo(actionRowHeight)
            }
        }

        currentPageInfoRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(pageInfoRowHeight)
        }

        if let item = extensionContext!.inputItems.first as? NSExtensionItem,
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ShareGeneralViewController.cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(ShareGeneralViewController.cancel))
    }
}

extension ShareGeneralViewController {

    func actionOpenInFirefox() {
        animateToActionDoneView(withTitle: "Opening Firefox")
    }

    func actionLoadInBackground() {
        animateToActionDoneView(withTitle: "Loading in Firefox")
    }

    func actionBookmarkThisPage() {
        animateToActionDoneView(withTitle: "Bookmarked")
    }

    func actionAddToReadingList() {
        animateToActionDoneView(withTitle: "Added to Reading List")
    }

    func actionSentToDevice() {
        let vc = SubVC(nibName: nil, bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
