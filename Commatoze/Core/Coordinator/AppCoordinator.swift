//

import UIKit

class AppCoordinator: CoordinatorBase {
	static let shared = AppCoordinator()

	override func start() {
		// no-op
	}

	override func finish() {
		// no-op
	}
}

extension AppCoordinator: AppCoordinatorInput {
	func startContentTable() {
		let activity = NSUserActivity(activityType: "ContentTableViewController")
		UIApplication.shared
			.requestSceneSessionActivation(
				nil,
				userActivity: activity,
				options: nil) { (err) in
				// TODO: log
			}
	}
}
