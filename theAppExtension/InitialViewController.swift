import UIKit
import SnapKit
import MobileCoreServices

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
        firstPage.validExtensionContext = extensionContext
        embedController = EmbeddedNavController(parent: self, rootViewController: firstPage)

        view.backgroundColor = UIColor(white: 0.0, alpha: 0.66)
    }
}
