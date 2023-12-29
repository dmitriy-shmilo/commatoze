//

import UIKit

protocol Storyboarded: AnyObject {
	static var storyboard: String { get }
	static var identifier: String { get }
	static func instantiate() -> Self
}

extension Storyboarded {
	static var identifier:String {
		return NSStringFromClass(self).components(separatedBy: ".")[1]
	}

	static func instantiate() -> Self {
		let storyboard = UIStoryboard(name: storyboard, bundle: Bundle.main)
		guard let result = storyboard.instantiateViewController(withIdentifier: identifier) as? Self else {
			fatalError("Can't find \(identifier) in \(storyboard)")
		}
		return result
	}
}
