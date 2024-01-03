//

import Foundation
import UIKit

class ContentTableCoordinator: CoordinatorBase {

	private let window: UIWindow
	private var rootViewController: ContentTableViewController?
	private var url: URL?

	init(with window: UIWindow, url: URL?) {
		self.window = window
		self.url = url
	}
	
	override func start() {
		let viewModel: ContentTableViewModel
		if let url = url {
			viewModel = .init(with: url)
		} else {
			viewModel = .init()
		}

		rootViewController = ContentTableViewController.instantiate()
		rootViewController?.viewModel = viewModel
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
