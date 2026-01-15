//
//  NotificationTestData.swift
//  NotimanagerTestDataFramework
//
//  Created for feature-1768473183452-7a7rg9upp
//  Test Data Framework - Notification Test Data
//

import Foundation

// MARK: - Notification Test Data

/// Test data for notification configuration and testing
public struct NotificationTestData: TestData {
    public let id: String
    public let version: String
    public let environment: String
    public let tags: [String]
    public let relationships: [String: String]
    
    /// Notification title
    public let title: String
    
    /// Notification body content
    public let body: String
    
    /// Notification position
    public let position: String
    
    /// Notification category
    public let category: String
    
    /// Expected notification size
    public let size: NotificationSize
    
    /// Notification priority
    public let priority: NotificationPriority
    
    /// Should this notification be intercepted?
    public let shouldBeIntercepted: Bool
    
    /// Expected time to display (in seconds)
    public let displayDuration: TimeInterval
    
    /// Custom sound identifier (if any)
    public let sound: String?
    
    /// Attachments for this notification
    public let attachments: [NotificationAttachment]
    
    /// Initialize notification test data
    public init(
        id: String,
        version: String = "1.0",
        environment: String = "universal",
        tags: [String] = [],
        relationships: [String: String] = [:],
        title: String,
        body: String,
        position: String,
        category: String = "test",
        size: NotificationSize = .banner,
        priority: NotificationPriority = .normal,
        shouldBeIntercepted: Bool = true,
        displayDuration: TimeInterval = 5.0,
        sound: String? = nil,
        attachments: [NotificationAttachment] = []
    ) {
        self.id = id
        self.version = version
        self.environment = environment
        self.tags = tags
        self.relationships = relationships
        self.title = title
        self.body = body
        self.position = position
        self.category = category
        self.size = size
        self.priority = priority
        self.shouldBeIntercepted = shouldBeIntercepted
        self.displayDuration = displayDuration
        self.sound = sound
        self.attachments = attachments
    }
    
    /// Validate the notification test data
    public func validate() throws {
        guard !id.isEmpty else {
            throw TestDataError.validationFailed("Notification ID cannot be empty")
        }
        
        guard !title.isEmpty else {
            throw TestDataError.validationFailed("Notification title cannot be empty")
        }
        
        guard !body.isEmpty else {
            throw TestDataError.validationFailed("Notification body cannot be empty")
        }
        
        guard displayDuration > 0 else {
            throw TestDataError.validationFailed("Display duration must be greater than 0")
        }
        
        // Validate position format
        let validPositions = ["topLeft", "topMiddle", "topRight", "middleLeft", "deadCenter", "middleRight", "bottomLeft", "bottomMiddle", "bottomRight"]
        guard validPositions.contains(position) else {
            throw TestDataError.validationFailed("Invalid position: \(position)")
        }
    }
}

// MARK: - Supporting Types

/// Size categories for notifications
public enum NotificationSize: String, Codable {
    case banner
    case alert
    case modal
    
    var width: CGFloat {
        switch self {
        case .banner: return 320
        case .alert: return 400
        case .modal: return 600
        }
    }
    
    var height: CGFloat {
        switch self {
        case .banner: return 80
        case .alert: return 200
        case .modal: return 400
        }
    }
}

/// Priority levels for notifications
public enum NotificationPriority: String, Codable {
    case low
    case normal
    case high
    case critical
}

/// Notification attachment information
public struct NotificationAttachment: Codable {
    public let id: String
    public let type: AttachmentType
    public let url: String?
    public let data: String? // Base64 encoded data
    
    public init(id: String, type: AttachmentType, url: String? = nil, data: String? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.data = data
    }
}

/// Types of notification attachments
public enum AttachmentType: String, Codable {
    case image
    case audio
    case video
    case document
}

// MARK: - Test Data Collections

/// Collection of notification test data for various scenarios
public class NotificationTestDataFactory {
    
    /// Create standard test notifications
    public static func createStandardNotifications() -> TestDataCollection<NotificationTestData> {
        let notifications = [
            NotificationTestData(
                id: "test_notification_001",
                tags: ["standard", "banner"],
                title: "Test Notification",
                body: "This is a standard test notification",
                position: "topMiddle",
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "test_notification_002",
                tags: ["standard", "large"],
                title: "Large Test Notification",
                body: "This is a larger test notification with more content to test the sizing and positioning",
                position: "deadCenter",
                size: .alert,
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "test_notification_003",
                tags: ["priority", "high"],
                title: "High Priority Test",
                body: "This is a high priority test notification",
                position: "topRight",
                priority: .high,
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "test_notification_004",
                tags: ["corner", "bottom"],
                title: "Bottom Left Test",
                body: "This notification should appear in the bottom left corner",
                position: "bottomLeft",
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "test_notification_005",
                tags: ["edge", "right"],
                title: "Right Edge Test",
                body: "This notification should appear on the right edge",
                position: "middleRight",
                shouldBeIntercepted: true
            ),
            
            // Test notification that should NOT be intercepted (too large for banner)
            NotificationTestData(
                id: "test_notification_006",
                tags: ["panel", "large"],
                title: "Notification Center Panel",
                body: "This is a large notification that should appear in the Notification Center panel, not as a banner",
                position: "deadCenter",
                size: .modal,
                shouldBeIntercepted: false
            )
        ]
        
        return TestDataCollection(
            version: "1.0",
            environment: "universal",
            records: notifications,
            metadata: [
                "description": "Standard test notifications for basic functionality",
                "author": "TestDataFramework",
                "created": "2025-01-15"
            ]
        )
    }
    
    /// Create edge case notifications
    public static func createEdgeCaseNotifications() -> TestDataCollection<NotificationTestData> {
        let notifications = [
            NotificationTestData(
                id: "edge_case_001",
                tags: ["empty", "minimal"],
                title: "Empty",
                body: "",
                position: "topLeft",
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "edge_case_002",
                tags: ["long", "text"],
                title: "Very Long Title That Should Wrap and Test the Layout System for Proper Display and Handling",
                body: "This is a very long notification body that should test the text wrapping and layout capabilities of the notification system. It contains multiple sentences and should demonstrate how the system handles lengthy content.",
                position: "bottomMiddle",
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "edge_case_003",
                tags: ["special", "characters"],
                title: "Special Chars: áéíóú 中文 🎉",
                body: "Testing special characters: áéíóú, 中文, 🎉, and other Unicode characters",
                position: "middleLeft",
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "edge_case_004",
                tags: ["emoji", "rich"],
                title: "🎉 Rich Content Test 🎉",
                body: "Testing 🚀 emoji 💡 and special formatting 🔥 in notifications",
                position: "topRight",
                shouldBeIntercepted: true
            ),
            
            NotificationTestData(
                id: "edge_case_005",
                tags: ["attachment", "image"],
                title: "Image Attachment",
                body: "Notification with image attachment",
                position: "deadCenter",
                shouldBeIntercepted: true,
                attachments: [
                    NotificationAttachment(
                        id: "image_001",
                        type: .image,
                        url: "https://example.com/test-image.png"
                    )
                ]
            )
        ]
        
        return TestDataCollection(
            version: "1.0",
            environment: "universal",
            records: notifications,
            metadata: [
                "description": "Edge case notifications for testing boundary conditions",
                "author": "TestDataFramework",
                "created": "2025-01-15"
            ]
        )
    }
    
    /// Create environment-specific notifications
    public static func createEnvironmentNotifications() -> [TestDataCollection<NotificationTestData>] {
        return [
            TestDataCollection(
                version: "1.0",
                environment: "development",
                records: [
                    NotificationTestData(
                        id: "dev_notification_001",
                        tags: ["development", "debug"],
                        title: "[DEV] Debug Notification",
                        body: "This is a development-only notification",
                        position: "topMiddle",
                        shouldBeIntercepted: true
                    ),
                    NotificationTestData(
                        id: "dev_notification_002",
                        tags: ["development", "verbose"],
                        title: "[DEV] Verbose Test",
                        body: "Development notification with detailed information for debugging purposes",
                        position: "bottomRight",
                        shouldBeIntercepted: true
                    )
                ],
                metadata: [
                    "description": "Development-specific notifications",
                    "environment": "development"
                ]
            ),
            
            TestDataCollection(
                version: "1.0",
                environment: "testing",
                records: [
                    NotificationTestData(
                        id: "test_notification_001",
                        tags: ["testing", "automated"],
                        title: "[TEST] Automated Test",
                        body: "Automated test notification for CI/CD pipeline",
                        position: "deadCenter",
                        shouldBeIntercepted: true
                    ),
                    NotificationTestData(
                        id: "test_notification_002",
                        tags: ["testing", "performance"],
                        title: "[TEST] Performance Test",
                        body: "Performance testing notification with large content",
                        position: "topLeft",
                        shouldBeIntercepted: true
                    )
                ],
                metadata: [
                    "description": "Testing-specific notifications",
                    "environment": "testing"
                ]
            ),
            
            TestDataCollection(
                version: "1.0",
                environment: "production",
                records: [
                    NotificationTestData(
                        id: "prod_notification_001",
                        tags: ["production", "realistic"],
                        title: "Real App Notification",
                        body: "This looks like a real application notification",
                        position: "topRight",
                        shouldBeIntercepted: true
                    ),
                    NotificationTestData(
                        id: "prod_notification_002",
                        tags: ["production", "user"],
                        title: "Message from User",
                        body: "A realistic notification that users might receive",
                        position: "bottomMiddle",
                        shouldBeIntercepted: true
                    )
                ],
                metadata: [
                    "description": "Production-like notifications for realistic testing",
                    "environment": "production"
                ]
            )
        ]
    }
}