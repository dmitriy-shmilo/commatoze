//

import Foundation
import CocoaLumberjackSwift

class Log {
	enum Verbosity {
		case verbose
		case debug
		case info
		case warn
		case error
	}
	
	private var tag = ""

	init(tagged type: AnyClass) {
		tag = String(describing: type)
	}

	func logVerbose(message: String) {
		DDLogVerbose(DDLogMessageFormat(stringLiteral: message), tag: tag)
	}

	func logDebug(message: String) {
		DDLogVerbose(DDLogMessageFormat(stringLiteral: message), tag: tag)
	}

	func logInfo(message: String) {
		DDLogVerbose(DDLogMessageFormat(stringLiteral: message), tag: tag)
	}

	func logWarn(message: String) {
		DDLogVerbose(DDLogMessageFormat(stringLiteral: message), tag: tag)
	}

	func logError(message: String) {
		DDLogVerbose(DDLogMessageFormat(stringLiteral: message), tag: tag)
	}
}
