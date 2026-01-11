import Foundation
import CloudKit
import SpectraCore

/// Sync status
public enum SyncStatus: Sendable, Equatable {
    case idle
    case syncing
    case succeeded(Date)
    case failed(String)
    case accountUnavailable
    case networkUnavailable
}

/// Protocol for objects that can be synced via CloudKit
public protocol CloudSyncable {
    var recordType: String { get }
    static var recordTypeName: String { get }
    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord
    static func from(record: CKRecord) -> Self?
}

/// CloudKit sync manager for Spectra data
@MainActor
public final class CloudSyncManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var status: SyncStatus = .idle
    @Published public private(set) var lastSyncDate: Date?
    @Published public private(set) var isAvailable: Bool = false
    
    // MARK: - Private
    
    private let container: CKContainer
    private let database: CKDatabase
    private let zoneID: CKRecordZone.ID
    
    private static let zoneName = "SpectraZone"
    private var zoneCreated = false
    
    // MARK: - Init
    
    public init(containerIdentifier: String = "iCloud.com.spectra.app") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        self.zoneID = CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
    }
    
    // MARK: - Public API
    
    /// Check CloudKit availability
    public func checkAvailability() async {
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                isAvailable = true
                self.status = .idle
                
            case .noAccount:
                isAvailable = false
                self.status = .accountUnavailable
                
            case .restricted, .couldNotDetermine, .temporarilyUnavailable:
                isAvailable = false
                self.status = .accountUnavailable
                
            @unknown default:
                isAvailable = false
                self.status = .accountUnavailable
            }
        } catch {
            isAvailable = false
            self.status = .failed(error.localizedDescription)
        }
    }
    
    /// Setup sync zone (call on first launch)
    public func setupZone() async throws {
        guard !zoneCreated else { return }
        
        let zone = CKRecordZone(zoneID: zoneID)
        
        do {
            _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
            zoneCreated = true
        } catch let error as CKError {
            // Zone already exists is fine
            if error.code == .serverRecordChanged || error.code == .zoneNotFound {
                zoneCreated = true
            } else {
                throw error
            }
        }
    }
    
    /// Save records to CloudKit
    public func save<T: CloudSyncable>(_ items: [T]) async throws {
        guard isAvailable else {
            throw SyncError.notAvailable
        }
        
        status = .syncing
        
        do {
            try await setupZone()
            
            let records = items.map { $0.toRecord(zoneID: zoneID) }
            
            let result = try await database.modifyRecords(
                saving: records,
                deleting: [],
                savePolicy: .changedKeys
            )
            
            _ = result.saveResults // Handle results if needed
            
            let now = Date()
            lastSyncDate = now
            status = .succeeded(now)
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }
    
    /// Fetch all records of a type
    public func fetch<T: CloudSyncable>(type: T.Type) async throws -> [T] {
        guard isAvailable else {
            throw SyncError.notAvailable
        }
        
        status = .syncing
        
        do {
            try await setupZone()
            
            let query = CKQuery(
                recordType: T.recordTypeName,
                predicate: NSPredicate(value: true)
            )
            
            var results: [T] = []
            var cursor: CKQueryOperation.Cursor? = nil
            
            repeat {
                let (matchResults, newCursor) = try await database.records(
                    matching: query,
                    inZoneWith: zoneID,
                    desiredKeys: nil,
                    resultsLimit: CKQueryOperation.maximumResults
                )
                
                for (_, result) in matchResults {
                    if case .success(let record) = result,
                       let item = T.from(record: record) {
                        results.append(item)
                    }
                }
                
                cursor = newCursor
            } while cursor != nil
            
            let now = Date()
            lastSyncDate = now
            status = .succeeded(now)
            
            return results
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }
    
    /// Delete records
    public func delete(recordIDs: [CKRecord.ID]) async throws {
        guard isAvailable else {
            throw SyncError.notAvailable
        }
        
        status = .syncing
        
        do {
            _ = try await database.modifyRecords(
                saving: [],
                deleting: recordIDs
            )
            
            let now = Date()
            lastSyncDate = now
            status = .succeeded(now)
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }
    
    /// Subscribe to changes
    public func subscribeToChanges() async throws {
        guard isAvailable else { return }
        
        let subscription = CKDatabaseSubscription(subscriptionID: "spectra-changes")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            _ = try await database.modifySubscriptions(saving: [subscription], deleting: [])
        } catch let error as CKError {
            // Subscription already exists is fine
            if error.code != .serverRejectedRequest {
                throw error
            }
        }
    }
    
    /// Process remote changes
    public func processRemoteChanges() async throws -> [CKRecord] {
        guard isAvailable else {
            throw SyncError.notAvailable
        }
        
        status = .syncing
        
        do {
            try await setupZone()
            
            var changedRecords: [CKRecord] = []
            var token: CKServerChangeToken? = loadChangeToken()
            
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            config.previousServerChangeToken = token
            
            let changes = try await database.recordZoneChanges(
                inZoneWith: zoneID,
                since: token
            )
            
            for modification in changes.modificationResultsByID {
                if case .success(let result) = modification.value {
                    changedRecords.append(result.record)
                }
            }
            
            // Save new token
            let newToken = changes.changeToken
            saveChangeToken(newToken)
            
            let now = Date()
            lastSyncDate = now
            status = .succeeded(now)
            
            return changedRecords
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Private
    
    private func loadChangeToken() -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: "spectra.sync.changeToken"),
              let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data) else {
            return nil
        }
        return token
    }
    
    private func saveChangeToken(_ token: CKServerChangeToken) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "spectra.sync.changeToken")
        }
    }
}

/// Sync errors
public enum SyncError: Error, Sendable {
    case notAvailable
    case zoneFailed
    case saveFailed
    case fetchFailed
}
