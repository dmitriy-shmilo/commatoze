//

import Foundation

class CoordinatorBase: Coordinator {
	weak var parent: Coordinator?
	var children =  [Coordinator]()

	func start() {
		fatalError("start is not implemented")
	}

	func finish() {
		parent?.childDidFinish(self)
	}

	func child(coordinator: Coordinator, didFinishWith result: Int, userData: Any?) {
		childDidFinish(coordinator)
	}
}
