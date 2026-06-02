import SwiftUI

/// Root of the notch panel. A black notch shape that springs open from a slim
/// resting bar into the full reader, mirroring boring.notch's drop-down feel.
struct NotchView: View {
    @EnvironmentObject var engine: RSVPEngine
    @EnvironmentObject var notch: NotchViewModel

    private var size: CGSize {
        notch.isOpen ? NotchMetrics.openSize : NotchMetrics.closedSize
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchShape(
                    topCornerRadius: notch.isOpen ? NotchMetrics.openTopCornerRadius : NotchMetrics.closedTopCornerRadius,
                    bottomCornerRadius: notch.isOpen ? NotchMetrics.openBottomCornerRadius : NotchMetrics.closedBottomCornerRadius
                )
                .fill(.black)
                .frame(width: size.width, height: size.height)
                .shadow(color: .black.opacity(notch.isOpen ? 0.55 : 0.0), radius: 10, y: 5)

                if notch.isOpen {
                    NotchContentView()
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))
                }
            }
            Spacer(minLength: 0)
        }
        .frame(width: NotchMetrics.windowSize.width, height: NotchMetrics.windowSize.height, alignment: .top)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: notch.isOpen)
        .preferredColorScheme(.dark)
    }
}
