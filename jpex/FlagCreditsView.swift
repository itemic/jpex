import SwiftUI

struct FlagCreditsView: View {
  var title: String
  var resource: String
  @State private var credits: [FlagArtworkCredit] = []
  @State private var loadFailed = false

  var body: some View {
    List {
      ForEach(credits) { credit in
        Section(credit.name) {
          Text(credit.author)
            .font(.footnote)
            .foregroundStyle(.secondary)
          if let note = credit.note, !note.isEmpty {
            Text(note)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          if let source = URL(string: credit.sourceURL) {
            Link("Source", destination: source)
          }
          if let license = URL(string: credit.licenseURL) {
            Link(credit.license, destination: license)
          } else {
            Text(credit.license)
          }
        }
      }
      if loadFailed {
        Text("Credits unavailable")
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      do {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
          loadFailed = true
          return
        }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        credits = try JSONDecoder().decode([FlagArtworkCredit].self, from: Data(contentsOf: url))
      } catch {
        loadFailed = true
      }
    }
  }
}

private struct FlagArtworkCredit: Decodable, Identifiable {
  var name: String
  var author: String
  var sourceURL: String
  var license: String
  var licenseURL: String
  var note: String?
  var id: String { name + "|" + sourceURL }
}
