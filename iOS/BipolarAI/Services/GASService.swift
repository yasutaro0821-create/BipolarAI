//
//  GASService.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  GAS API communication service
//

import Foundation

/// GAS API通信エラー
enum GASServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        case .decodingError(let error):
            return "データの解析エラー: \(error.localizedDescription)"
        }
    }
}

/// GAS API通信サービス
class GASService {
    static let shared = GASService()
    
    private let endpointURL: URL
    
    private init() {
        guard let url = URL(string: Constants.GAS_ENDPOINT_URL) else {
            fatalError("Invalid GAS endpoint URL")
        }
        self.endpointURL = url
    }
    
    /// 日次ログを送信して計算結果を取得
    /// - Parameter log: 日次ログデータ
    /// - Returns: 計算結果
    func submitDailyLog(_ log: DailyLog) async throws -> CalculationResult {
        // JSONエンコード
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(log) else {
            throw GASServiceError.invalidResponse
        }
        
        // リクエスト作成
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // リクエスト送信
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // レスポンス確認
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GASServiceError.invalidResponse
            }
            
            // エラーチェック
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw GASServiceError.serverError(errorMessage)
            }
            
            // JSONデコード
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(CalculationResult.self, from: data)
            
            // エラーチェック
            if !result.ok {
                throw GASServiceError.serverError(result.error ?? "Unknown error")
            }
            
            return result
            
        } catch let error as GASServiceError {
            throw error
        } catch {
            throw GASServiceError.networkError(error)
        }
    }
    
    /// ヘルスチェック
    func healthCheck() async throws -> Bool {
        guard let url = URL(string: "\(Constants.GAS_ENDPOINT_URL)?mode=health") else {
            throw GASServiceError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ok = json["ok"] as? Bool {
            return ok
        }
        
        return false
    }
}

