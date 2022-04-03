import XCTest
@testable import AsyncURLSession

final class AsyncURLSessionTests: XCTestCase {
    func testNoProgress() async throws {
        let content = """
Utilitatis causa amicitia est quaesita.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Collatio igitur ista te nihil iuvat. Honesta oratio, Socratica, Platonis etiam. Primum in nostrane potestate est, quid meminerimus? Duo Reges: constructio interrete. Quid, si etiam iucunda memoria est praeteritorum malorum? Si quidem, inquit, tollerem, sed relinquo. An nisi populari fama?

Quamquam id quidem licebit iis existimare, qui legerint. Summum a vobis bonum voluptas dicitur. At hoc in eo M. Refert tamen, quo modo. Quid sequatur, quid repugnet, vident. Iam id ipsum absurdum, maximum malum neglegi.
"""

        let (url, _) = try await AsyncURLSession.shared.url(from: .init(string: "https://filesamples.com/samples/document/txt/sample1.txt")!)

        XCTAssertEqual(content, try String(contentsOf: url))
    }

    func testProgress() async throws {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.appendingPathComponent("100MB.txt")
        let (progress, response) = try await AsyncURLSession.shared.download(from: .init(string: "https://filesamples.com/samples/document/txt/sample1.txt")!, location: url)
        let all = response.expectedContentLength

        for try await current in progress {
            let progress = Double(current) / Double(all)

            print(Int(progress * 100), "%")
        }
    }
}
