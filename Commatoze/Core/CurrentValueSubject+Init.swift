//

import Combine

extension CurrentValueSubject where Failure == Never {
	convenience init(value: Output) {
		self.init(value)
	}
}
