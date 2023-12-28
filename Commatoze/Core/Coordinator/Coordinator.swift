//

import Foundation

protocol Coordinator: AnyObject {
	var parent: Coordinator? { get set }
	var children: [Coordinator] { get set }

	func start()
	func finish()
}

extension Coordinator {
	func addChild(coordinator: Coordinator) {
		coordinator.parent = self
		children.append(coordinator)
		coordinator.start()
	}

	func childDidFinish(_ coordinator: Coordinator) {
		guard let index = children.firstIndex(where: { coordinator === $0 }) else {
			return
		}
		coordinator.parent = nil
		children.remove(at: index)
	}

	func child(coordinator: Coordinator, didFinishWith result: Int, userData: Any?) {
		childDidFinish(coordinator)
	}

	func finishWithResult(_ result: Int, userData: Any?) {
		parent?.child(coordinator: self, didFinishWith: result, userData: userData)
	}
}
