//

import Foundation
import UIKit

class ContentTableCoordinator: CoordinatorBase {

	private let window: UIWindow
	private var rootViewController: ContentTableViewController?
	private var url: URL?

	private var replaceOnOpen = false

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
			where result == DocumentPickerCoordinator.resultOpen:
			rootViewController?.viewModel.stopPickingFile()
			guard let urls = userData as? [URL],
				  let url = urls.first else {
				break
			}

			if replaceOnOpen {
				self.url = url
				rootViewController?.viewModel.readFile(url: url)
				return
			}

			AppCoordinator.shared.startContentTable(url: url)
		case is DocumentPickerCoordinator:
			rootViewController?.viewModel.stopPickingFile()
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

	func presentOpenFilePicker(willReplaceContent: Bool) {
		guard let rootViewController = rootViewController else {
			return
		}
		replaceOnOpen = willReplaceContent
		let coordinator = DocumentPickerCoordinator(
			with: rootViewController)
		addChild(coordinator: coordinator)
	}

	func presentSaveFilePicker(for url: URL) {
		guard let rootViewController = rootViewController else {
			return
		}
		let coordinator = DocumentPickerCoordinator(
			with: rootViewController,
			exportUrl: url)
		addChild(coordinator: coordinator)
	}
}
