import Testing
@testable import SpectraUI

@Suite("SpectraUI Tests")
struct SpectraUITests {
    
    @Test("Theme colors exist")
    func themeColors() {
        // Just verify types compile correctly
        _ = SpectraColors.accent
        _ = SpectraColors.success
        _ = SpectraColors.healthOK
    }
    
    @Test("Spacing constants are ordered")
    func spacingOrder() {
        #expect(SpectraSpacing.xs < SpectraSpacing.sm)
        #expect(SpectraSpacing.sm < SpectraSpacing.md)
        #expect(SpectraSpacing.md < SpectraSpacing.lg)
        #expect(SpectraSpacing.lg < SpectraSpacing.xl)
    }
}
