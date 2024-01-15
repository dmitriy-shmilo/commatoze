//

import UIKit

extension UIView {
	@IBInspectable
	var cornerRadius: CGFloat {
		get {
			return layer.cornerRadius
		}
		set {
			layer.cornerRadius = newValue
			if cornerRadius > 0.0 {
				clipsToBounds = true
			}
		}
	}
}
