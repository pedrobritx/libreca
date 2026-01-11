import Foundation

/// Context for evaluating rules against a channel
public struct RuleEvaluationContext: Sendable {
    public let channel: Channel
    public let streams: [MediaStream]
    public let isFavorite: Bool
    public let isHidden: Bool
    
    public init(
        channel: Channel,
        streams: [MediaStream] = [],
        isFavorite: Bool = false,
        isHidden: Bool = false
    ) {
        self.channel = channel
        self.streams = streams
        self.isFavorite = isFavorite
        self.isHidden = isHidden
    }
    
    /// Best health status among all streams
    public var bestHealthStatus: StreamHealthStatus {
        let statuses = streams.map { $0.healthStatus }
        if statuses.contains(.ok) { return .ok }
        if statuses.contains(.unknown) { return .unknown }
        if statuses.contains(.flaky) { return .flaky }
        return .dead
    }
}

/// Engine for evaluating smart folder rules
public struct RuleEngine: Sendable {
    public init() {}
    
    /// Evaluate if a channel matches the folder rules
    public func evaluate(rules: FolderRules, context: RuleEvaluationContext) -> Bool {
        let groupResults = rules.groups.map { evaluate(group: $0, context: context) }
        
        switch rules.groupLogic {
        case .and:
            return groupResults.allSatisfy { $0 }
        case .or:
            return groupResults.contains { $0 }
        }
    }
    
    /// Evaluate a single rule group
    public func evaluate(group: RuleGroup, context: RuleEvaluationContext) -> Bool {
        let conditionResults = group.conditions.map { evaluate(condition: $0, context: context) }
        
        switch group.logic {
        case .and:
            return conditionResults.allSatisfy { $0 }
        case .or:
            return conditionResults.contains { $0 }
        }
    }
    
    /// Evaluate a single condition
    public func evaluate(condition: RuleCondition, context: RuleEvaluationContext) -> Bool {
        let fieldValue = getFieldValue(field: condition.field, context: context)
        
        switch condition.operator {
        case .equals:
            return fieldValue?.lowercased() == condition.value?.lowercased()
            
        case .notEquals:
            return fieldValue?.lowercased() != condition.value?.lowercased()
            
        case .contains:
            guard let value = condition.value?.lowercased(),
                  let field = fieldValue?.lowercased() else { return false }
            return field.contains(value)
            
        case .notContains:
            guard let value = condition.value?.lowercased(),
                  let field = fieldValue?.lowercased() else { return true }
            return !field.contains(value)
            
        case .startsWith:
            guard let value = condition.value?.lowercased(),
                  let field = fieldValue?.lowercased() else { return false }
            return field.hasPrefix(value)
            
        case .endsWith:
            guard let value = condition.value?.lowercased(),
                  let field = fieldValue?.lowercased() else { return false }
            return field.hasSuffix(value)
            
        case .in:
            guard let values = condition.values,
                  let field = fieldValue?.lowercased() else { return false }
            return values.map { $0.lowercased() }.contains(field)
            
        case .notIn:
            guard let values = condition.values,
                  let field = fieldValue?.lowercased() else { return true }
            return !values.map { $0.lowercased() }.contains(field)
            
        case .isTrue:
            return fieldValue == "true"
            
        case .isFalse:
            return fieldValue == "false"
            
        case .isEmpty:
            return fieldValue?.isEmpty ?? true
            
        case .isNotEmpty:
            return !(fieldValue?.isEmpty ?? true)
        }
    }
    
    /// Get the string value for a field from the context
    private func getFieldValue(field: RuleField, context: RuleEvaluationContext) -> String? {
        switch field {
        case .name:
            return context.channel.name
        case .group:
            return context.channel.group
        case .country:
            return context.channel.country
        case .language:
            return context.channel.language
        case .tvgId:
            return context.channel.tvgId
        case .isFavorite:
            return context.isFavorite ? "true" : "false"
        case .isHidden:
            return context.isHidden ? "true" : "false"
        case .healthStatus:
            return context.bestHealthStatus.rawValue
        }
    }
    
    /// Filter channels by rules
    public func filter(
        channels: [Channel],
        rules: FolderRules,
        contextProvider: (Channel) -> RuleEvaluationContext
    ) -> [Channel] {
        channels.filter { channel in
            let context = contextProvider(channel)
            return evaluate(rules: rules, context: context)
        }
    }
}
