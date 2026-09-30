import SwiftUI

struct PlayerOverlayView: View {
    @Binding var isMuted: Bool
    @Binding var isVisible: Bool
    let remainingText: String?
    let onSleepTapped: () -> Void
    let onBack: () -> Void
    
    private let circleSize: CGFloat = 52

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: AppSpacing.l) {
                Button(action: onBack) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: circleSize, height: circleSize)
                        .background(AppColors.overlayBG, in: Circle())
                }
                Button(action: { isMuted.toggle() }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: circleSize, height: circleSize)
                        .background(AppColors.overlayBG, in: Circle())
                }
                if let text = remainingText {
                    Text(text)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.l)
                        .padding(.vertical, AppSpacing.m)
                        .background(AppColors.overlayBG)
                        .clipShape(Capsule())
                        .onTapGesture { onSleepTapped() }
                } else {
                    Button(action: onSleepTapped) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: circleSize, height: circleSize)
                            .background(AppColors.overlayBG, in: Circle())
                    }
                }
            }
            .padding(.bottom, AppSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
    }
}
