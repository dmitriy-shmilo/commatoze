//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(
		_ application: UIApplication,
		 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
	) -> Bool {
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
		builder.remove(menu: .format)
		builder.remove(menu: .view)

		builder.replaceChildren(ofMenu: .file) { _ in
			MainMenu.fileMenu()
		}

		builder.replaceChildren(ofMenu: .edit) { _ in
			MainMenu.editMenu()
		}
	}
}

