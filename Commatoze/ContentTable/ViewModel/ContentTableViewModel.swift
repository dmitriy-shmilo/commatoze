//

import Combine
import LibCSV

// TODO: get rid of this dependency in the view model
import Spreadsheet

class ContentTableViewModel {
	let cellChanged = PassthroughSubject<SheetIndex, Never>()

	let data = CurrentValueSubject<[String], Never>([String]())
	let columns = CurrentValueSubject<[String], Never>([String]())
	let rows = CurrentValueSubject<[String], Never>([String]())
	let currentFile = CurrentValueSubject<URL?, Never>(nil)

	private var subscriptions = Set<AnyCancellable>()

	// TODO: abstract libcsv away
	private let parser = CSVReader()
	private var rawData = [String]()
	private var rawColumns = [String]()
	private var readingHeader = true
	private var rawUrl: URL?

	init() {
		parser.delegate = self

		data.combineLatest(columns)
			.map { (data, columns) in
				guard data.count > 0, columns.count > 0 else {
					return []
				}

				return (0..<(data.count / columns.count)).map {
					return "\($0)"
				}
			}
			.assign(to: \.value, on: rows)
			.store(in: &subscriptions)
	}

	func readFile(url: URL) {
		guard let data = try? Data(contentsOf: url) else {
			return
		}
		do {
			rawUrl = url
			rawData = []
			rawColumns = []
			// TODO: load in background
			try parser.parse(data: data)
		} catch {
			// TODO: report errors to the user
		}
	}

	func setField(at index: SheetIndex, to value: String) {
		guard index.index >= 0 && index.index < data.value.count else {
			return
		}
		data.value.withUnsafeMutableBufferPointer {
			$0[index.index] = value
		}
		cellChanged.send(index)
	}
}

extension ContentTableViewModel: CSVReaderDelegate {
	func csvReader(_ reader: LibCSV.CSVReader, didReadField field: String) {
		if readingHeader {
			rawColumns.append(field)
		} else {
			rawData.append(field)
		}
	}

	func csvReader(_ reader: LibCSV.CSVReader, didReadRowTerminatedBy character: Character?) {
		readingHeader = false
	}

	func csvReaderDidFinish(_ reader: LibCSV.CSVReader) {
		data.send(rawData)
		columns.send(rawColumns)
		currentFile.send(rawUrl)
	}
}
