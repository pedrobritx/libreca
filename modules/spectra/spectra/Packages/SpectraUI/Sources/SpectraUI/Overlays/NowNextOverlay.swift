import SwiftUI
import SpectraEPG

/// Now/Next program overlay
public struct NowNextOverlay: View {
    public let nowNext: NowNext
    public let channelName: String
    
    public init(nowNext: NowNext, channelName: String) {
        self.nowNext = nowNext
        self.channelName = channelName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpectraSpacing.md) {
            // Channel name
            Text(channelName)
                .font(SpectraTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Now playing
            if let now = nowNext.now {
                ProgramInfo(
                    label: "NOW",
                    program: now,
                    showProgress: true
                )
            }
            
            // Up next
            if let next = nowNext.next {
                ProgramInfo(
                    label: "NEXT",
                    program: next,
                    showProgress: false
                )
            }
        }
        .padding(SpectraSpacing.lg)
        .frame(maxWidth: 400, alignment: .leading)
        .background(SpectraColors.playerOverlay)
        .cornerRadius(SpectraRadius.lg)
    }
}

/// Program information display
public struct ProgramInfo: View {
    public let label: String
    public let program: Program
    public let showProgress: Bool
    
    public init(label: String, program: Program, showProgress: Bool = false) {
        self.label = label
        self.program = program
        self.showProgress = showProgress
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpectraSpacing.xs) {
            // Label
            Text(label)
                .font(SpectraTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            // Title
            Text(program.title)
                .font(SpectraTypography.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            // Time
            HStack {
                Text(formatTime(program.startTime))
                Text("-")
                Text(formatTime(program.endTime))
                
                if let category = program.category {
                    Text("•")
                    Text(category)
                }
            }
            .font(SpectraTypography.subheadline)
            .foregroundColor(.gray)
            
            // Progress bar (for current program)
            if showProgress, let progress = program.progress() {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                        
                        Rectangle()
                            .fill(SpectraColors.accent)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 4)
                .cornerRadius(2)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// Mini now/next badge for channel list
public struct NowNextBadge: View {
    public let nowTitle: String?
    public let progress: Double?
    
    public init(nowTitle: String?, progress: Double? = nil) {
        self.nowTitle = nowTitle
        self.progress = progress
    }
    
    public var body: some View {
        if let title = nowTitle {
            HStack(spacing: SpectraSpacing.xs) {
                if let progress = progress {
                    // Mini progress indicator
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(SpectraColors.accent, lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(-90))
                }
                
                Text(title)
                    .font(SpectraTypography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        NowNextOverlay(
            nowNext: NowNext(
                channelId: "espn",
                now: Program(
                    channelId: "espn",
                    title: "NFL Sunday Night Football: Chiefs vs Eagles",
                    category: "Sports",
                    startTime: Date().addingTimeInterval(-30 * 60),
                    endTime: Date().addingTimeInterval(90 * 60)
                ),
                next: Program(
                    channelId: "espn",
                    title: "SportsCenter",
                    category: "Sports News",
                    startTime: Date().addingTimeInterval(90 * 60),
                    endTime: Date().addingTimeInterval(150 * 60)
                )
            ),
            channelName: "ESPN HD"
        )
    }
}
