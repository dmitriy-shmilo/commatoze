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
		rootViewController?.coordinator = self
		window.rootViewController = rootViewController
		window.makeKeyAndVisible()
	}

	override func child(
		coordinator: Coordinator,
		didFinishWith result: Int,
		userData: Any?
	) {
		switch coordinator {
		case is DocumentPickerCoordinator
			where result == DocumentPickerCoordinator.resultCancel:
			break
		case is DocumentPickerCoordinator
			where result == DocumentPickerCoordinator.resultOpen:
			guard let urls = userData as? [URL],
				  let url = urls.first else {
				break
			}
			AppCoordinator.shared.startContentTable(url: url)
		default:
			break
		}

		childDidFinish(coordinator)
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

	func presentFilePicker() {
		guard let rootViewController = rootViewController else {
			return
		}
		let coordinator = DocumentPickerCoordinator(with: rootViewController)
		addChild(coordinator: coordinator)
	}
}
