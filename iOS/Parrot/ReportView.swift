import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    let kid: Kid

    private var summary: ReportSummary {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
        return ReportSummary.assemble(sessions: kid.sessionRecords, from: start, to: end)
    }

    private var pdfURL: URL? {
        ReportPDF.generate(kidName: kid.name, summary: summary)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last 30 Days")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)

                        statRow("Sessions", "\(summary.sessionCount)")
                        statRow("Words practiced", "\(summary.attemptCount)")
                        statRow("Practice time", "\(summary.totalMinutes) min")
                        statRow("Overall accuracy", summary.overallAccuracy.percentText)

                        if !summary.soundStats.isEmpty {
                            Text("By Sound")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .padding(.top, 8)
                            ForEach(summary.soundStats, id: \.sound) { stat in
                                statRow(stat.sound, stat.accuracy.percentText)
                            }
                        }
                    }
                    .padding(20)
                    .glassCard()
                    .padding(20)
                }
            }
            .navigationTitle("\(kid.name)'s Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closeReportButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("shareReportButton")
                    }
                }
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
        }
    }
}
