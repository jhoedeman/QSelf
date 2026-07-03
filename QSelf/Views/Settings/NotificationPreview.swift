import SwiftUI

/// Static mock of a lock-screen notification banner, per the brief's
/// "Notification preview showing lock-screen appearance" spec. Not wired to
/// real UNNotificationContent — purely illustrative of what the reminder
/// will look like.
struct NotificationPreview: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.apexArc)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("QSelf")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("now")
                        .font(.caption)
                        .foregroundStyle(Color.apexTextTertiary)
                }
                Text("Time to log how you're feeling")
                    .font(.subheadline)
                    .foregroundStyle(Color.apexTextSecondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NotificationPreview()
        .padding()
        .background(Color.apexCanvas)
        .preferredColorScheme(.dark)
}
