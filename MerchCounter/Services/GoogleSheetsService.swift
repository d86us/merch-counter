import Foundation
import Security

final class GoogleSheetsService: @unchecked Sendable {
    private let spreadsheetId: String
    private let credentials: ServiceAccountCredentials
    private var accessToken: String?
    private var tokenExpiration: Date?
    private let session = URLSession.shared

    init() throws {
        self.spreadsheetId = "1Gp_FVFH6KJWFTgMEY87V5Tvl4cZ8YRyCSxtXa8cfC2Y"
        guard let url = Bundle.main.url(forResource: "GoogleServiceAccount", withExtension: "json") else {
            throw ServiceError.credentialsNotFound
        }
        let data = try Data(contentsOf: url)
        credentials = try JSONDecoder().decode(ServiceAccountCredentials.self, from: data)
    }

    // MARK: - Public API

    func appendRecord(_ record: SurveyRecord) async throws {
        let token = try await getValidToken()

        try await ensureHeaders(token: token)
        try await appendRow(record, token: token)
    }

    // MARK: - Token Management

    private func getValidToken() async throws -> String {
        if let token = accessToken, let exp = tokenExpiration, Date() < exp {
            return token
        }
        return try await refreshToken()
    }

    private func refreshToken() async throws -> String {
        let jwt = try buildJWT()
        let (data, response) = try await session.data(for: tokenRequest(with: jwt))

        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw ServiceError.tokenExchangeFailed
        }

        let tokenResp = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tokenResp.accessToken
        tokenExpiration = Date().addingTimeInterval(TimeInterval(tokenResp.expiresIn))
        return tokenResp.accessToken
    }

    private func buildJWT() throws -> String {
        let header = #"{"alg":"RS256","typ":"JWT"}"#.data(using: .utf8)!.base64URLString
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + 3600
        let payload = """
        {"iss":"\(credentials.clientEmail)","scope":"https://www.googleapis.com/auth/spreadsheets","aud":"https://oauth2.googleapis.com/token","exp":\(exp),"iat":\(now)}
        """.data(using: .utf8)!.base64URLString

        let signingInput = "\(header).\(payload)"
        guard let inputData = signingInput.data(using: .utf8) else {
            throw ServiceError.jwtBuildFailed
        }
        let signature = try rsaSHA256Sign(data: inputData)
        return "\(header).\(payload).\(signature.base64URLString)"
    }

    private func tokenRequest(with jwt: String) -> URLRequest {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        req.httpBody = body.data(using: .utf8)
        return req
    }

    // MARK: - RSA Signing

    private func rsaSHA256Sign(data: Data) throws -> Data {
        let pkcs1 = try extractRSAKeyFromPKCS8(credentials.privateKey)
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ]
        guard let secKey = SecKeyCreateWithData(pkcs1 as CFData, attributes as CFDictionary, nil) else {
            throw ServiceError.keyImportFailed
        }
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            secKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) as Data? else {
            throw ServiceError.signingFailed
        }
        return signature
    }

    /// Converts PKCS#8 private key PEM to PKCS#1 DER data (required by Security framework).
    private func extractRSAKeyFromPKCS8(_ pem: String) throws -> Data {
        let base64 = pem
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") }
            .joined()
        guard let der = Data(base64Encoded: base64) else {
            throw ServiceError.keyParseFailed
        }
        // PKCS#8: SEQUENCE { INTEGER(0), SEQUENCE { OID, NULL }, OCTET STRING { RSAPrivateKey } }
        var pos = 0
        // Outer SEQUENCE
        guard der[pos] == 0x30 else { throw ServiceError.keyParseFailed }
        pos += 1
        pos += readLength(in: der, at: pos).bytesConsumed
        // Version INTEGER
        guard der[pos] == 0x02 else { throw ServiceError.keyParseFailed }
        pos += 1
        pos = skipLength(in: der, at: pos)
        // AlgorithmIdentifier SEQUENCE
        guard der[pos] == 0x30 else { throw ServiceError.keyParseFailed }
        pos += 1
        pos = skipLength(in: der, at: pos)
        // OCTET STRING containing PKCS#1 key
        guard der[pos] == 0x04 else { throw ServiceError.keyParseFailed }
        pos += 1
        let keyLen = readLength(in: der, at: pos)
        pos += keyLen.bytesConsumed
        guard pos + keyLen.value <= der.count else { throw ServiceError.keyParseFailed }
        return der.subdata(in: pos..<pos + keyLen.value)
    }

    // MARK: - Sheet Operations

    private func ensureHeaders(token: String) async throws {
        try await writeHeaders(token: token)
    }

    private func writeHeaders(token: String) async throws {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1!1:1?valueInputOption=RAW")!
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ValueRange(
            range: "Sheet1!1:1",
            majorDimension: "ROWS",
            values: [SurveyRecord.sheetHeaders]
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (_, resp) = try await session.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw ServiceError.headerWriteFailed
        }
    }

    private func appendRow(_ record: SurveyRecord, token: String) async throws {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ValueRange(
            range: "Sheet1",
            majorDimension: "ROWS",
            values: [record.sheetRowValues]
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await session.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard (200...299).contains(httpResp.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ServiceError.apiError(httpResp.statusCode, text)
        }
    }
}

// MARK: - Models

private struct ServiceAccountCredentials: Codable {
    let type: String
    let projectId: String
    let privateKeyId: String
    let privateKey: String
    let clientEmail: String
    let clientId: String
    let authUri: String
    let tokenUri: String

    enum CodingKeys: String, CodingKey {
        case type
        case projectId = "project_id"
        case privateKeyId = "private_key_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case clientId = "client_id"
        case authUri = "auth_uri"
        case tokenUri = "token_uri"
    }
}

private struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct ValueRange: Codable {
    let range: String?
    let majorDimension: String?
    let values: [[String]]?
}

extension GoogleSheetsService {
    func fetchRowCounts() async throws -> (total: Int, today: Int) {
        let token = try await getValidToken()
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1!A:A")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw ServiceError.invalidResponse
        }
        let range = try JSONDecoder().decode(ValueRange.self, from: data)
        let dataRows = (range.values ?? []).dropFirst()
        let total = dataRows.count
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let todayStr = f.string(from: Date())
        let today = dataRows.filter { $0.first == todayStr }.count
        return (total, today)
    }
}

// MARK: - Errors

enum ServiceError: Error, LocalizedError {
    case credentialsNotFound
    case tokenExchangeFailed
    case jwtBuildFailed
    case keyImportFailed
    case signingFailed
    case keyParseFailed
    case invalidResponse
    case apiError(Int, String)
    case headerWriteFailed

    var errorDescription: String? {
        switch self {
        case .credentialsNotFound:
            return "Service account JSON not found in app bundle."
        case .tokenExchangeFailed:
            return "Failed to authenticate with Google. Check your service account credentials."
        case .jwtBuildFailed:
            return "Failed to build authentication token."
        case .keyImportFailed:
            return "Failed to import private key. Check your service account JSON."
        case .signingFailed:
            return "Failed to sign authentication request."
        case .keyParseFailed:
            return "Invalid private key format in service account JSON."
        case .invalidResponse:
            return "Invalid response from server. Check your network connection."
        case .apiError(let code, let msg):
            return "Google API error (\(code)): \(msg)"
        case .headerWriteFailed:
            return "Failed to write headers to the sheet."
        }
    }
}

// MARK: - DER Parsing Helpers

private func skipLength(in data: Data, at index: Int) -> Int {
    let result = readLength(in: data, at: index)
    return index + result.bytesConsumed + result.value
}

private func readLength(in data: Data, at index: Int) -> (value: Int, bytesConsumed: Int) {
    guard index < data.count else { return (0, 1) }
    let first = data[index]
    if first & 0x80 == 0 {
        return (Int(first), 1)
    } else {
        let count = Int(first & 0x7F)
        guard index + 1 + count <= data.count else { return (0, 1) }
        var length = 0
        for i in 0..<count {
            length = length * 256 + Int(data[index + 1 + i])
        }
        return (length, 1 + count)
    }
}

// MARK: - Base64URL

private extension Data {
    var base64URLString: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
