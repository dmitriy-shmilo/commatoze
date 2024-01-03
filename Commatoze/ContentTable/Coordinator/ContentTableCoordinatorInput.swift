//

import Foundation

protocol ContentTableCoordinatorInput: Coordinator {
	func presentFilePicker(willReplaceContent: Bool)
	func close()
}
