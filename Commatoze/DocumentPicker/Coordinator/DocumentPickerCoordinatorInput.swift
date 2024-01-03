//

import Foundation

protocol DocumentPickerCoordinatorInput: Coordinator {
	func cancel()
	func confirm(urls: [URL])
}
