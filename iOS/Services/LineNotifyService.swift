//
//  LineNotifyService.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  LINE Notify API service
//

import Foundation

/// LINE Notify APIエラー
enum LineNotifyError: Error, LocalizedError {
    case invalidToken
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "LINE Notifyトークンが設定されていません"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}

/// LINE Notify APIサービス
class LineNotifyService {
    static let shared = LineNotifyService()
    
    private let apiURL = "https://notify-api.line.me/api/notify"
    private var accessToken: String?
    
    private init() {
        // トークンは後で設定（UserDefaultsなどから読み込む）
        loadToken()
    }
    
    /// トークンを設定
    func setToken(_ token: String) {
        self.accessToken = token
        // UserDefaultsに保存
        UserDefaults.standard.set(token, forKey: "line_notify_token")
    }
    
    /// トークンを読み込み
    private func loadToken() {
        self.accessToken = UserDefaults.standard.string(forKey: "line_notify_token")
    }
    
    /// メッセージを送信
    /// - Parameter message: 送信するメッセージ
    func sendMessage(_ message: String) async throws {
        guard let token = accessToken, !token.isEmpty else {
            throw LineNotifyError.invalidToken
        }
        
        guard let url = URL(string: apiURL) else {
            throw LineNotifyError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "message=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LineNotifyError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw LineNotifyError.serverError(errorMessage)
            }
            
        } catch let error as LineNotifyError {
            throw error
        } catch {
            throw LineNotifyError.networkError(error)
        }
    }
    
    /// トークンが設定されているか確認
    func hasToken() -> Bool {
        return accessToken != nil && !accessToken!.isEmpty
    }
}

