//

import Foundation
import UIKit

class ContentTableCoordinator: CoordinatorBase {

	let window: UIWindow
	var rootViewController: ContentTableViewController?

	init(with window: UIWindow) {
		self.window = window
	}
	
	override func start() {
		rootViewController = ContentTableViewController.instantiate()
		window.rootViewController = rootViewController
		window.makeKeyAndVisible()
	}
}

extension ContentTableCoordinator: ContentTableCoordinatorInput {
	func close() {
		guard let session = window.windowScene?.session else {
			return
		}
		UIApplication.shared.requestSceneSessionDestruction(
			session,
			options: nil)
	}
}
