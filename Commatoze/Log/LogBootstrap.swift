//

import Foundation
import CocoaLumberjackSwift

class LogBootstrap {
	static func setupLog() {
		let fileLogger = DDFileLogger()
		fileLogger.maximumFileSize = 100 * 1000
		DDLog.add(fileLogger)
		if let logger = DDTTYLogger.sharedInstance {
			DDLog.add(logger)
		}
	}
}
