import Foundation

/// Rule operator for smart folder matching
public enum RuleOperator: String, Codable, Sendable {
    case equals
    case notEquals = "not_equals"
    case contains
    case notContains = "not_contains"
    case startsWith = "starts_with"
    case endsWith = "ends_with"
    case `in`
    case notIn = "not_in"
    case isTrue = "is_true"
    case isFalse = "is_false"
    case isEmpty = "is_empty"
    case isNotEmpty = "is_not_empty"
}

/// Field to match against in a rule
public enum RuleField: String, Codable, Sendable {
    case name
    case group
    case country
    case language
    case tvgId = "tvg_id"
    case isFavorite = "is_favorite"
    case isHidden = "is_hidden"
    case healthStatus = "health_status"
}

/// A single rule condition
public struct RuleCondition: Codable, Sendable, Equatable {
    public let field: RuleField
    public let `operator`: RuleOperator
    public let value: String?
    public let values: [String]?
    
    public init(
        field: RuleField,
        operator: RuleOperator,
        value: String? = nil,
        values: [String]? = nil
    ) {
        self.field = field
        self.operator = `operator`
        self.value = value
        self.values = values
    }
    
    // Convenience initializers for common patterns
    public static func nameContains(_ text: String) -> RuleCondition {
        RuleCondition(field: .name, operator: .contains, value: text)
    }
    
    public static func groupEquals(_ group: String) -> RuleCondition {
        RuleCondition(field: .group, operator: .equals, value: group)
    }
    
    public static func countryEquals(_ country: String) -> RuleCondition {
        RuleCondition(field: .country, operator: .equals, value: country)
    }
    
    public static func languageEquals(_ language: String) -> RuleCondition {
        RuleCondition(field: .language, operator: .equals, value: language)
    }
    
    public static func isFavorite() -> RuleCondition {
        RuleCondition(field: .isFavorite, operator: .isTrue)
    }
    
    public static func isHealthy() -> RuleCondition {
        RuleCondition(field: .healthStatus, operator: .in, values: ["ok", "unknown"])
    }
    
    public static func isDead() -> RuleCondition {
        RuleCondition(field: .healthStatus, operator: .equals, value: "dead")
    }
}

/// Logic for combining rules
public enum RuleLogic: String, Codable, Sendable {
    case and
    case or
}

/// A group of rules combined with logic
public struct RuleGroup: Codable, Sendable, Equatable {
    public let logic: RuleLogic
    public let conditions: [RuleCondition]
    
    public init(logic: RuleLogic = .and, conditions: [RuleCondition]) {
        self.logic = logic
        self.conditions = conditions
    }
}

/// Complete rules configuration for a smart folder
public struct FolderRules: Codable, Sendable, Equatable {
    public let groups: [RuleGroup]
    public let groupLogic: RuleLogic
    
    public init(groups: [RuleGroup], groupLogic: RuleLogic = .and) {
        self.groups = groups
        self.groupLogic = groupLogic
    }
    
    /// Simple constructor for single group of AND conditions
    public static func all(_ conditions: [RuleCondition]) -> FolderRules {
        FolderRules(groups: [RuleGroup(logic: .and, conditions: conditions)])
    }
    
    /// Simple constructor for single group of OR conditions
    public static func any(_ conditions: [RuleCondition]) -> FolderRules {
        FolderRules(groups: [RuleGroup(logic: .or, conditions: conditions)])
    }
}
