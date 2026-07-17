import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var pro

    var body: some View {
        NavigationStack {
            ZStack {
                ClassroomBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "bird.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(Theme.coral)
                            .padding(.top, 26)

                        Text("Parrot Pro")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)

                        Text("Unlimited target sounds and PDF progress reports.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)

                        VStack(alignment: .leading, spacing: 14) {
                            benefit(symbol: "waveform", title: "Unlimited sounds",
                                    detail: "Free covers two target sounds per kid. Pro removes the limit.")
                            benefit(symbol: "doc.richtext.fill", title: "PDF reports",
                                    detail: "Export clean progress summaries to share at appointments.")
                            benefit(symbol: "lock.shield.fill", title: "Still private",
                                    detail: "Pro adds features, never tracking. Data stays on device.")
                        }
                        .padding(20)
                        .glassCard()
                        .padding(.horizontal, 20)

                        Button {
                            Task {
                                await pro.purchase()
                                if pro.isPro { dismiss() }
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(pro.isPro ? "Pro is active" : "Subscribe")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                if !pro.isPro {
                                    Text("\(pro.priceText) per month, cancel anytime")
                                        .font(.system(size: 12, design: .rounded))
                                        .opacity(0.85)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Theme.sky)
                            }
                            .foregroundStyle(.white)
                        }
                        .disabled(pro.isPro || pro.isWorking)
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("subscribeButton")

                        Button("Restore purchases") {
                            Task {
                                await pro.restore()
                                if pro.isPro { dismiss() }
                            }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("closePaywallButton")
                }
            }
        }
    }

    private func benefit(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.coral)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
