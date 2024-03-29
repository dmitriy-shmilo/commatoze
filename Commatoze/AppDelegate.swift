//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(
		_ application: UIApplication,
		 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
	) -> Bool {
		LogBootstrap.setupLog()
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions) -> UISceneConfiguration {
			let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)

			switch options.userActivities.first?.activityType {
			case "ContentTableViewController":
				config.storyboard = .init(name: "ContentTable", bundle: .main)
				config.delegateClass = ContentTableSceneDelegate.self
			default:
				break
			}

			return config
	}

	override func buildMenu(with builder: UIMenuBuilder) {
		MainMenuController.buildMenu(with: builder)
	}
}

