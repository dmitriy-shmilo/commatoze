//

import UIKit

class ContentTableSceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	weak var coordinator: ContentTableCoordinator?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = (scene as? UIWindowScene) else {
			return
		}
		let url = connectionOptions.userActivities
			.first?
			.userInfo?["URL"] as? String ?? ""
		let window = UIWindow(windowScene: scene)
		let coordinator = ContentTableCoordinator(with: window, url: URL(string: url))
		AppCoordinator.shared.addChild(coordinator: coordinator)
		self.coordinator = coordinator
		self.window = window
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		coordinator?.finish()
	}
}

