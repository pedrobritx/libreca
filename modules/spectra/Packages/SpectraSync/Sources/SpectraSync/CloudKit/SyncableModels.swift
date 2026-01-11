import Foundation
import CloudKit
import SpectraCore

// MARK: - CloudKit Record Types

public enum RecordType {
    public static let source = "Source"
    public static let folder = "Folder"
    public static let folderItem = "FolderItem"
    public static let favorite = "Favorite"
    public static let hidden = "Hidden"
}

// MARK: - Source CloudKit Support

extension Source: CloudSyncable {
    public var recordType: String { RecordType.source }
    public static var recordTypeName: String { RecordType.source }
    
    public func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["name"] = name
        record["type"] = type.rawValue
        record["url"] = url?.absoluteString
        record["refreshPolicy"] = refreshPolicy.rawValue
        record["epgURL"] = epgURL?.absoluteString
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
    
    public static func from(record: CKRecord) -> Source? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String,
              let typeRaw = record["type"] as? String,
              let type = SourceType(rawValue: typeRaw) else {
            return nil
        }
        
        let urlString = record["url"] as? String
        let refreshPolicyRaw = record["refreshPolicy"] as? String ?? RefreshPolicy.manual.rawValue
        let epgURLString = record["epgURL"] as? String
        
        return Source(
            id: id,
            name: name,
            type: type,
            url: urlString.flatMap { URL(string: $0) },
            refreshPolicy: RefreshPolicy(rawValue: refreshPolicyRaw) ?? .manual,
            epgURL: epgURLString.flatMap { URL(string: $0) },
            createdAt: record["createdAt"] as? Date ?? Date(),
            updatedAt: record["updatedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - Folder CloudKit Support

extension Folder: CloudSyncable {
    public var recordType: String { RecordType.folder }
    public static var recordTypeName: String { RecordType.folder }
    
    public func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["name"] = name
        record["order"] = order
        record["type"] = type.rawValue
        record["ruleJSON"] = ruleJSON
        record["iconName"] = iconName
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
    
    public static func from(record: CKRecord) -> Folder? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let name = record["name"] as? String,
              let order = record["order"] as? Int,
              let typeRaw = record["type"] as? String,
              let type = FolderType(rawValue: typeRaw) else {
            return nil
        }
        
        return Folder(
            id: id,
            name: name,
            order: order,
            type: type,
            ruleJSON: record["ruleJSON"] as? String,
            iconName: record["iconName"] as? String,
            createdAt: record["createdAt"] as? Date ?? Date(),
            updatedAt: record["updatedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - FolderItem CloudKit Support

extension FolderItem: CloudSyncable {
    public var recordType: String { RecordType.folderItem }
    public static var recordTypeName: String { RecordType.folderItem }
    
    public func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["folderId"] = folderId.uuidString
        record["channelId"] = channelId
        record["order"] = order
        record["addedAt"] = addedAt
        
        return record
    }
    
    public static func from(record: CKRecord) -> FolderItem? {
        guard let folderIdString = record["folderId"] as? String,
              let folderId = UUID(uuidString: folderIdString),
              let channelId = record["channelId"] as? String,
              let order = record["order"] as? Int else {
            return nil
        }
        
        return FolderItem(
            folderId: folderId,
            channelId: channelId,
            order: order,
            addedAt: record["addedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - Favorite CloudKit Support

extension Favorite: CloudSyncable {
    public var recordType: String { RecordType.favorite }
    public static var recordTypeName: String { RecordType.favorite }
    
    public func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: channelId, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["channelId"] = channelId
        record["addedAt"] = addedAt
        
        return record
    }
    
    public static func from(record: CKRecord) -> Favorite? {
        guard let channelId = record["channelId"] as? String else {
            return nil
        }
        
        return Favorite(
            channelId: channelId,
            addedAt: record["addedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - Hidden CloudKit Support

extension Hidden: CloudSyncable {
    public var recordType: String { RecordType.hidden }
    public static var recordTypeName: String { RecordType.hidden }
    
    public func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: channelId, zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record["channelId"] = channelId
        record["hiddenAt"] = hiddenAt
        
        return record
    }
    
    public static func from(record: CKRecord) -> Hidden? {
        guard let channelId = record["channelId"] as? String else {
            return nil
        }
        
        return Hidden(
            channelId: channelId,
            hiddenAt: record["hiddenAt"] as? Date ?? Date()
        )
    }
}
