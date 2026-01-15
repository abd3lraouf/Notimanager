//
//  APITestFixtures.swift
//  NotimanagerTests
//
//  Created on 2025-01-15.
//

import XCTest
import Foundation
@testable import Notimanager

/// API test fixtures for integration testing
/// Provides reusable patterns for testing API interactions and network operations
class APITestFixtures {

    // MARK: - Properties

    private(set) var mockURLSession: MockURLSession!
    private(set) var originalURLSession: URLSession?

    // MARK: - Session Setup

    /// Creates a mock URL session for testing
    /// - Returns: Configured mock URL session
    func createMockURLSession() -> MockURLSession {
        return MockURLSession()
    }

    /// Sets up a mock URL session for testing
    /// - Returns: Configured mock URL session
    func setupMockURLSession() -> MockURLSession {
        // Store original session for restoration
        originalURLSession = URLSession.shared

        // Create and configure mock session
        mockURLSession = MockURLSession()

        return mockURLSession
    }

    /// Sets a mock response for a specific endpoint
    /// - Parameters:
    ///   - endpoint: Endpoint URL or path
    ///   - data: Response data
    ///   - statusCode: HTTP status code
    func setMockResponse(for endpoint: String, data: Data, statusCode: Int) {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.example.com\(endpoint)")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        mockURLSession?.mockData = data
        mockURLSession?.mockResponse = response
        mockURLSession?.mockError = nil
    }

    /// Creates test settings response data
    /// - Returns: Settings response data
    func createTestSettingsResponse() -> Data {
        let settings: [String: Any] = [
            "settings": [
                ["key": "test_setting", "value": "test_value"],
                ["key": "another_setting", "value": "another_value"]
            ]
        ]
        return (try? JSONSerialization.data(withJSONObject: settings)) ?? Data()
    }

    /// Creates a test notification dictionary
    /// - Parameters:
    ///   - id: Notification ID
    ///   - title: Notification title
    ///   - body: Notification body
    /// - Returns: Notification dictionary
    func createTestNotification(
        id: String = UUID().uuidString,
        title: String = "Test Notification",
        body: String = "Test body"
    ) -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "body": body,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    /// Restores the original URL session
    func restoreOriginalURLSession() {
        mockURLSession = nil
        originalURLSession = nil
    }

    // MARK: - Response Setup

    /// Sets up a mock success response
    /// - Parameters:
    ///   - data: Response data
    ///   - statusCode: HTTP status code (default: 200)
    ///   - headers: Response headers (default: empty)
    func setupMockSuccessResponse(
        data: Data,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )
        
        mockURLSession?.mockData = data
        mockURLSession?.mockResponse = response
        mockURLSession?.mockError = nil
    }

    /// Sets up a mock error response
    /// - Parameters:
    ///   - error: Error to return
    ///   - statusCode: HTTP status code (default: 500)
    ///   - headers: Response headers (default: empty)
    func setupMockErrorResponse(
        error: Error,
        statusCode: Int = 500,
        headers: [String: String] = [:]
    ) {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )
        
        mockURLSession?.mockData = nil
        mockURLSession?.mockResponse = response
        mockURLSession?.mockError = error
    }

    /// Sets up a mock JSON response
    /// - Parameters:
    ///   - jsonObject: JSON object to serialize
    ///   - statusCode: HTTP status code (default: 200)
    ///   - headers: Response headers (default: JSON content type)
    func setupMockJSONResponse(
        jsonObject: Any,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"]
    ) {
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            setupMockSuccessResponse(data: data, statusCode: statusCode, headers: headers)
        } catch {
            XCTFail("Failed to serialize JSON object: \(error)")
        }
    }

    /// Sets up a mock network timeout
    func setupMockTimeout() {
        let timeoutError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
        )
        setupMockErrorResponse(error: timeoutError, statusCode: 0)
    }

    /// Sets up a mock network unreachable error
    func setupMockNetworkUnreachable() {
        let unreachableError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "Network is unreachable"]
        )
        setupMockErrorResponse(error: unreachableError, statusCode: 0)
    }

    // MARK: - Test Data Creation

    /// Creates test notification data for API requests
    /// - Parameter count: Number of notifications to create
    /// - Returns: Array of notification dictionaries
    func createTestNotificationData(count: Int = 3) -> [[String: Any]] {
        var notifications: [[String: Any]] = []
        
        for i in 0..<count {
            let notification: [String: Any] = [
                "id": UUID().uuidString,
                "title": "Test Notification \(i)",
                "body": "This is test notification \(i)",
                "timestamp": Date().timeIntervalSince1970,
                "priority": i % 3, // 0: low, 1: medium, 2: high
                "source": "test_app"
            ]
            notifications.append(notification)
        }
        
        return notifications
    }

    /// Creates test setting data for API requests
    /// - Parameter count: Number of settings to create
    /// - Returns: Dictionary of settings
    func createTestSettingData(count: Int = 3) -> [String: Any] {
        var settings: [String: Any] = [:]
        
        for i in 0..<count {
            let key = "test_setting_\(i)"
            let value: Any = i % 2 == 0 ? "test_value_\(i)" : i
            settings[key] = value
        }
        
        return settings
    }

    /// Creates test user profile data
    /// - Returns: User profile dictionary
    func createTestUserProfileData() -> [String: Any] {
        return [
            "id": UUID().uuidString,
            "name": "Test User",
            "email": "test@example.com",
            "preferences": [
                "notification_style": "banner",
                "position_preference": "top_right",
                "auto_move_enabled": true
            ],
            "created_at": Date().timeIntervalSince1970,
            "updated_at": Date().timeIntervalSince1970
        ]
    }

    // MARK: - Request Verification

    /// Verifies that a request was made with expected parameters
    /// - Parameters:
    ///   - url: Expected URL
    ///   - method: Expected HTTP method
    ///   - headers: Expected headers (optional)
    ///   - body: Expected request body (optional)
    /// - Returns: True if the request matches expectations
    func verifyRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) -> Bool {
        guard let lastRequest = mockURLSession?.lastRequest else {
            XCTFail("No request was made")
            return false
        }

        // Verify URL
        guard let requestURL = lastRequest.url?.absoluteString,
              requestURL == url else {
            XCTFail("Request URL mismatch. Expected: \(url), Got: \(lastRequest.url?.absoluteString ?? "nil")")
            return false
        }

        // Verify method
        guard let requestMethod = lastRequest.httpMethod,
              requestMethod == method else {
            XCTFail("Request method mismatch. Expected: \(method), Got: \(lastRequest.httpMethod ?? "nil")")
            return false
        }

        // Verify headers if provided
        if let expectedHeaders = headers {
            for (key, value) in expectedHeaders {
                guard let actualValue = lastRequest.value(forHTTPHeaderField: key),
                      actualValue == value else {
                    XCTFail("Header mismatch for \(key). Expected: \(value), Got: \(lastRequest.value(forHTTPHeaderField: key) ?? "nil")")
                    return false
                }
            }
        }

        // Verify body if provided
        if let expectedBody = body {
            guard let actualBody = lastRequest.httpBody,
                  actualBody == expectedBody else {
                XCTFail("Request body mismatch")
                return false
            }
        }

        return true
    }

    /// Verifies the number of requests made
    /// - Parameter expectedCount: Expected number of requests
    /// - Returns: True if the count matches
    func verifyRequestCount(_ expectedCount: Int) -> Bool {
        guard let actualCount = mockURLSession?.requestCount else {
            XCTFail("Mock session not available")
            return false
        }

        return actualCount == expectedCount
    }

    /// Resets the mock session state
    func resetMockSession() {
        mockURLSession?.reset()
    }

    // MARK: - Cleanup

    func cleanup() {
        restoreOriginalURLSession()
    }
}

// MARK: - Mock URL Session

/// Mock URL session for testing API calls
class MockURLSession: URLSession {

    // MARK: - Properties

    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?
    private(set) var requestCount: Int = 0

    // MARK: - URLSession Override

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        lastRequest = request
        requestCount += 1

        return MockURLSessionDataTask {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }

    // MARK: - Reset

    func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        lastRequest = nil
        requestCount = 0
    }
}

// MARK: - Mock URL Session Data Task

/// Mock URL session data task
class MockURLSessionDataTask: URLSessionDataTask {

    private let completionHandler: () -> Void

    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }

    override func resume() {
        completionHandler()
    }
}

// MARK: - API Test Case

/// Base test case for API-related integration tests
/// Automatically sets up and tears down mock URL session
class APITestCase: NotimanagerTestCase {

    // MARK: - Properties

    let apiFixtures = APITestFixtures()
    var mockSession: MockURLSession?

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()
        
        // Setup mock session
        mockSession = apiFixtures.setupMockURLSession()
    }

    override func tearDown() {
        // Cleanup
        apiFixtures.cleanup()
        mockSession = nil
        
        super.tearDown()
    }

    // MARK: - Convenience Methods

    /// Sets up a successful JSON response
    func setupSuccessResponse<T: Encodable>(_ object: T, statusCode: Int = 200) {
        do {
            let data = try JSONEncoder().encode(object)
            apiFixtures.setupMockSuccessResponse(data: data, statusCode: statusCode)
        } catch {
            XCTFail("Failed to encode response object: \(error)")
        }
    }

    /// Sets up a network error
    func setupNetworkError(_ error: Error? = nil) {
        let networkError = error ?? NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        apiFixtures.setupMockErrorResponse(error: networkError)
    }

    /// Verifies the last request made
    func verifyLastRequest(
        url: String,
        method: String = "GET",
        headers: [String: String]? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            apiFixtures.verifyRequest(url: url, method: method, headers: headers),
            "Request verification failed",
            file: file,
            line: line
        )
    }
}

// MARK: - API Client Mock

/// Mock API client for testing
class MockAPIClient {

    // MARK: - Properties

    var session: MockURLSession
    var baseURL: URL

    // MARK: - Initialization

    init(session: MockURLSession = MockURLSession(), baseURL: URL = URL(string: "https://api.test.com")!) {
        self.session = session
        self.baseURL = baseURL
    }

    // MARK: - Mock Methods

    func getNotifications(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let request = URLRequest(url: baseURL.appendingPathComponent("notifications"))
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "MockAPIClient", code: -1, userInfo: nil)))
                return
            }

            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(jsonObject))
                } else {
                    completion(.failure(NSError(domain: "MockAPIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    func postSettings(_ settings: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("settings"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try JSONSerialization.data(withJSONObject: settings, options: [])
            request.httpBody = data
        } catch {
            completion(.failure(error))
            return
        }

        let task = session.dataTask(with: request) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
        task.resume()
    }
}