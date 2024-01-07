//

import Foundation

protocol ContentTableCoordinatorInput: Coordinator {
	func presentOpenFilePicker(willReplaceContent: Bool)
	func presentSaveFilePicker(for url: URL)
	func close()
}
