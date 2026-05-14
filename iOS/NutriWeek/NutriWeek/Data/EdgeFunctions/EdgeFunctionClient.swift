import Foundation
import Supabase

enum EdgeFunctionError: Error, LocalizedError {
    case httpStatus(code: Int, message: String, stage: String? = nil, details: String? = nil)
    case relay
    case decoding
    case aiTimeout
    case aiUnavailable
    case aiSchemaInvalid
    case aiRateLimited
    case unknown(message: String)

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code, let message, let stage, let details):
            let stageText = stage.map { " [\($0)]" } ?? ""
            let detailsText = details.map { " (\($0))" } ?? ""
            return "Edge function failed (\(code))\(stageText): \(message)\(detailsText)"
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
            throw map(error, functionName: functionName)
        }
    }

    func invoke<Response: Decodable>(_ functionName: String) async throws -> Response {
        do {
            return try await client.functions.invoke(functionName, decoder: decoder)
        } catch {
            throw map(error, functionName: functionName)
        }
    }

    private func map(_ error: Error, functionName: String) -> EdgeFunctionError {
        if let functionsError = error as? FunctionsError {
            switch functionsError {
            case .relayError:
                print("[EdgeFunctionClient] relay_error function=\(functionName)")
                return .relay
            case .httpError(let code, let data):
                let response = decodeErrorResponse(from: data)
                let logPayload = """
                [EdgeFunctionClient] http_error function=\(functionName) status=\(code) error=\(response.code ?? "unknown") stage=\(response.stage ?? "none") message=\(response.message) details=\(response.details ?? "none")
                """
                print(logPayload)
                if let mapped = mapStableCode(response.code) {
                    return mapped
                }
                return .httpStatus(
                    code: code,
                    message: response.message,
                    stage: response.stage,
                    details: response.details
                )
            }
        }

        if error is DecodingError {
            print("[EdgeFunctionClient] decoding_error function=\(functionName) message=\(error.localizedDescription)")
            return .decoding
        }

        print("[EdgeFunctionClient] unknown_error function=\(functionName) message=\(error.localizedDescription)")
        return .unknown(message: error.localizedDescription)
    }

    private func decodeErrorResponse(from data: Data) -> (code: String?, message: String, stage: String?, details: String?) {
        if data.isEmpty {
            return (nil, "No response body.", nil, nil)
        }

        if
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["message"] as? String ?? object["error"] as? String
        {
            let code = object["error"] as? String
            let stage = object["stage"] as? String
            let details = object["details"] as? String
            return (code, message, stage, details)
        }

        return (nil, String(decoding: data, as: UTF8.self), nil, nil)
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
