import Foundation
import SwiftData

@Model class SaveModel {
    var visitStatus: [VisitStatus] = []
    init() {
        visitStatus = Array(repeating: .never, count: 47)
    }
}

@main struct LegacyFixture {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let schema = Schema([SaveModel.self])
        let configuration = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)
        let model = SaveModel()
        model.visitStatus[0] = .passed
        model.visitStatus[12] = .lived
        model.visitStatus[46] = .stayed
        context.insert(model)
        try context.save()
        print("PASS: created legacy Japan-only disk store")
    }
}
