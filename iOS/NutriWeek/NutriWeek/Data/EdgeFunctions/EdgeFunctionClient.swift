import Foundation
import Supabase

enum EdgeFunctionError: Error, LocalizedError {
    case httpStatus(code: Int, message: String)
    case relay
    case decoding
    case aiTimeout
    case aiUnavailable
    case aiSchemaInvalid
    case aiRateLimited
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code, let message):
            return "Edge function failed (\(code)): \(message)"
        case .relay:
            return "Edge relay error."
        case .decoding:
            return "Edge response decoding failed."
        case .aiTimeout:
            return "AI request timed out."
        case .aiUnavailable:
            return "AI service unavailable."
        case .aiSchemaInvalid:
            return "AI response schema invalid."
        case .aiRateLimited:
            return "AI request rate limited."
        case .unknown(let message):
            return message
        }
    }
}

struct EdgeFunctionClient {
    private let client: SupabaseClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        client: SupabaseClient = SupabaseClientFactory.shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.client = client
        self.decoder = decoder
        self.encoder = encoder
    }

    func invoke<Request: Encodable, Response: Decodable>(
        _ functionName: String,
        payload: Request
    ) async throws -> Response {
        do {
            let options = FunctionInvokeOptions(body: payload, encoder: encoder)
            return try await client.functions.invoke(functionName, options: options, decoder: decoder)
        } catch {
            throw map(error)
        }
    }

    func invoke<Response: Decodable>(_ functionName: String) async throws -> Response {
        do {
            return try await client.functions.invoke(functionName, decoder: decoder)
        } catch {
            throw map(error)
        }
    }

    private func map(_ error: Error) -> EdgeFunctionError {
        if let functionsError = error as? FunctionsError {
            switch functionsError {
            case .relayError:
                return .relay
            case .httpError(let code, let data):
                let response = decodeErrorResponse(from: data)
                if let mapped = mapStableCode(response.code) {
                    return mapped
                }
                return .httpStatus(code: code, message: response.message)
            }
        }

        if error is DecodingError {
            return .decoding
        }

        return .unknown(message: error.localizedDescription)
    }

    private func decodeMessage(from data: Data) -> String {
        decodeErrorResponse(from: data).message
    }

    private func decodeErrorResponse(from data: Data) -> (code: String?, message: String) {
        if data.isEmpty {
            return (nil, "No response body.")
        }

        if
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["message"] as? String ?? object["error"] as? String
        {
            let code = object["error"] as? String
            return (code, message)
        }

        return (nil, String(decoding: data, as: UTF8.self))
    }

    private func mapStableCode(_ code: String?) -> EdgeFunctionError? {
        switch code {
        case "AI_TIMEOUT":
            return .aiTimeout
        case "AI_UNAVAILABLE":
            return .aiUnavailable
        case "AI_SCHEMA_INVALID":
            return .aiSchemaInvalid
        case "AI_RATE_LIMITED":
            return .aiRateLimited
        default:
            return nil
        }
    }
}
