import UIKit
import SnapKit
import MobileCoreServices

/*
 The initial view controller is full-screen and is the only one with a valid extension context.
 This view controller is just a wrapper with a semi-transparent background to darken the screen
 that embeds the share view controller which is designed to look like a popup.
 */

class EmbeddedNavController {
    weak var parent: UIViewController?
    var controllers = [UIViewController]()
    var navigationController: UINavigationController

    init (parent: UIViewController, rootViewController: UIViewController) {
        self.parent = parent
        navigationController = UINavigationController(rootViewController: rootViewController)

        parent.addChildViewController(navigationController)
        parent.view.addSubview(navigationController.view)

        let width = min(UIScreen.main.bounds.width, CGFloat(UX.topViewWidth))

        navigationController.view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(UX.topViewHeight)
        }

        navigationController.view.layer.cornerRadius = 8
        navigationController.view.layer.masksToBounds = true
    }

    deinit {
        navigationController.view.removeFromSuperview()
        navigationController.removeFromParentViewController()
    }
}

class InitialViewController: UIViewController {
    var embedController: EmbeddedNavController!

    override func viewDidLoad() {
        assert(extensionContext != nil)

        super.viewDidLoad()
        let firstPage = TopShareViewController()
        firstPage.delegate = self
        embedController = EmbeddedNavController(parent: self, rootViewController: firstPage)

        view.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
    }
}

extension InitialViewController: ShareViewControllerDelegate {
    func finish(afterDelay: TimeInterval) {
        UIView.animate(withDuration: 0.2, delay: afterDelay, options: [], animations: {
            self.view.alpha = 0
        }, completion: { (finished: Bool) in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
    }

    func getValidExtensionContext() -> NSExtensionContext? {
        return extensionContext
    }
}
