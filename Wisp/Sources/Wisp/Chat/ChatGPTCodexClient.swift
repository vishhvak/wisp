import Foundation
import CoreGraphics

// Talks to the ChatGPT Codex backend (chatgpt.com/backend-api/codex/responses) using the user's
// existing ChatGPT OAuth session — the same credentials the Codex CLI maintains in
// ~/.codex/auth.json. No API key, no proxy: the user's ChatGPT plan carries the tokens.
//
// The request/streaming contract is ported from a proven reference implementation:
//   • POST /responses with a Responses-API body (input_text / input_image parts)
//   • headers: Bearer access token + "chatgpt-account-id" + "OpenAI-Beta: responses=experimental"
//   • NO temperature (the backend 400s on it for reasoning models)
//   • reasoning: {effort, summary:"auto"} — stripped and retried if the backend names it
//     unsupported ("Unsupported parameter: X")
//   • SSE stream: text arrives as response.output_text.delta events
//
// Yields the same ChatStreamEvent stream as ClaudeClient, reusing InlineTagExtractor so teaching
// tags work identically regardless of which model is speaking.
final class ChatGPTCodexClient {

    private static let codexBaseURL = URL(string: "https://chatgpt.com/backend-api/codex")!
    private static let authFileURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/auth.json")

    // Set true after the backend rejects `reasoning` so later requests skip it outright.
    private var reasoningUnsupported = false

    // MARK: - Auth (rides the Codex CLI's session)

    private struct CodexStoredAuth {
        let accessToken: String
        let accountId: String
    }

    private func loadStoredAuth() -> CodexStoredAuth? {
        guard let authData = try? Data(contentsOf: Self.authFileURL),
              let parsedAuth = try? JSONSerialization.jsonObject(with: authData) as? [String: Any],
              let tokens = parsedAuth["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              let accountId = tokens["account_id"] as? String,
              !accessToken.isEmpty, !accountId.isEmpty else {
            return nil
        }
        return CodexStoredAuth(accessToken: accessToken, accountId: accountId)
    }

    // MARK: - Streaming

    func streamResponse(
        userMessageText: String,
        imageAttachments: [ChatImageAttachment] = [],
        modelIdentifier: String = WispConfig.chatModel
    ) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let streamingTask = Task {
                do {
                    var requestBody = self.buildResponsesBody(
                        userMessageText: userMessageText,
                        imageAttachments: imageAttachments,
                        modelIdentifier: modelIdentifier
                    )

                    var (byteStream, httpResponse) = try await self.openResponsesStream(body: requestBody)

                    // The backend names unsupported fields ("Unsupported parameter: X") — strip
                    // exactly the named field and retry, a couple of fields max.
                    var retryBudget = 2
                    while let failureStatus = Self.failureStatus(httpResponse), retryBudget > 0 {
                        guard failureStatus == 400 || failureStatus == 422 else { break }
                        let failureBody = try await Self.collectBodyText(byteStream)
                        guard let unsupportedField = Self.unsupportedParameterName(in: failureBody),
                              requestBody[unsupportedField] != nil else {
                            throw WispChatError.backend(status: failureStatus, body: failureBody)
                        }
                        WispLog.log("chat", "backend rejected '\(unsupportedField)' — retrying without it")
                        requestBody.removeValue(forKey: unsupportedField)
                        if unsupportedField == "reasoning" { self.reasoningUnsupported = true }
                        retryBudget -= 1
                        (byteStream, httpResponse) = try await self.openResponsesStream(body: requestBody)
                    }
                    if let failureStatus = Self.failureStatus(httpResponse) {
                        let failureBody = try await Self.collectBodyText(byteStream)
                        throw WispChatError.backend(status: failureStatus, body: failureBody)
                    }

                    // Buffers text across deltas so a tag split across two deltas is still matched.
                    let tagExtractor = InlineTagExtractor()

                    for try await sseLine in byteStream.lines {
                        guard sseLine.hasPrefix("data:") else { continue }
                        let jsonPayload = String(sseLine.dropFirst("data:".count))
                            .trimmingCharacters(in: .whitespaces)
                        if jsonPayload == "[DONE]" { break }

                        guard let textDelta = Self.outputTextDelta(fromEventJSON: jsonPayload) else { continue }
                        let extraction = tagExtractor.consume(textDelta)
                        if !extraction.cleanText.isEmpty {
                            continuation.yield(.textDelta(extraction.cleanText))
                        }
                        for annotation in extraction.annotations {
                            continuation.yield(.teachingAnnotation(annotation))
                        }
                    }

                    continuation.finish()
                } catch {
                    WispLog.log("chat", "ChatGPT stream failed: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                streamingTask.cancel()
            }
        }
    }

    // Opens the SSE stream, retrying once with freshly re-read credentials on 401 (the Codex CLI
    // refreshes ~/.codex/auth.json on its own schedule; a re-read usually picks up a newer token).
    // ponytail: no self-driven OAuth refresh — if a re-read still 401s, the fix is `codex login`.
    private func openResponsesStream(
        body: [String: Any]
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        for attempt in 0..<2 {
            guard let storedAuth = loadStoredAuth() else {
                throw WispChatError.notConnected
            }
            var request = URLRequest(url: Self.codexBaseURL.appendingPathComponent("responses"))
            request.httpMethod = "POST"
            request.timeoutInterval = 120
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(storedAuth.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(storedAuth.accountId, forHTTPHeaderField: "chatgpt-account-id")
            request.setValue("responses=experimental", forHTTPHeaderField: "OpenAI-Beta")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (byteStream, response) = try await URLSession.shared.bytes(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 401 && attempt == 0 {
                WispLog.log("chat", "ChatGPT 401 — re-reading ~/.codex/auth.json and retrying (run `codex login` if this persists)")
                continue
            }
            return (byteStream, response)
        }
        throw WispChatError.notConnected
    }

    // MARK: - Request body

    private func buildResponsesBody(
        userMessageText: String,
        imageAttachments: [ChatImageAttachment],
        modelIdentifier: String
    ) -> [String: Any] {
        var userContentParts: [[String: Any]] = []
        for imageAttachment in imageAttachments {
            userContentParts.append([
                "type": "input_image",
                "image_url": "data:\(imageAttachment.mediaType);base64,\(imageAttachment.base64EncodedImage)"
            ])
        }
        userContentParts.append(["type": "input_text", "text": userMessageText])

        var responsesBody: [String: Any] = [
            "input": [
                [
                    "role": "system",
                    "content": [["type": "input_text", "text": Self.wispSystemPrompt]]
                ],
                [
                    "role": "user",
                    "content": userContentParts
                ]
            ],
            "instructions": "",
            "model": modelIdentifier,
            "store": false,
            "stream": true
            // no temperature: the codex backend rejects it for reasoning models.
        ]
        if !reasoningUnsupported {
            responsesBody["reasoning"] = ["effort": WispConfig.chatReasoningEffort, "summary": "auto"]
        }
        return responsesBody
    }

    // MARK: - SSE parsing

    // Pulls the text out of one Responses-API SSE event: response.output_text.delta carries the
    // spoken text; everything else (reasoning summaries, lifecycle events) is ignored for now.
    private static func outputTextDelta(fromEventJSON eventJSON: String) -> String? {
        guard let eventData = eventJSON.data(using: .utf8),
              let parsedEvent = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any],
              parsedEvent["type"] as? String == "response.output_text.delta",
              let textDelta = parsedEvent["delta"] as? String, !textDelta.isEmpty else {
            return nil
        }
        return textDelta
    }

    private static func failureStatus(_ response: URLResponse) -> Int? {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 400 else { return nil }
        return statusCode
    }

    private static func unsupportedParameterName(in body: String) -> String? {
        guard let match = body.range(of: #"Unsupported parameter:?\s*['"]?([a-zA-Z_.]+)"#, options: .regularExpression) else {
            return nil
        }
        let matchedText = String(body[match])
        return matchedText
            .replacingOccurrences(of: #"Unsupported parameter:?\s*['"]?"#, with: "", options: .regularExpression)
    }

    private static func collectBodyText(_ byteStream: URLSession.AsyncBytes) async throws -> String {
        var collectedBytes: [UInt8] = []
        for try await byte in byteStream {
            collectedBytes.append(byte)
            if collectedBytes.count > 4096 { break }
        }
        return String(decoding: collectedBytes, as: UTF8.self)
    }

    // MARK: - System prompt

    // Teaches the model Wisp's voice AND the exact inline tag grammar InlineTagExtractor parses.
    private static let wispSystemPrompt = """
    You are Wisp, a small glowing companion that lives on the user's Mac. You can SEE their screen \
    (attached screenshots) and you SPEAK your answers aloud, so keep responses short, warm, and \
    conversational — a couple of sentences unless they ask for depth. Never use markdown, lists, \
    or code fences: you are a voice.

    You can draw directly on the user's screen by embedding tags INLINE in your response at the \
    moment you mention them. Coordinates are PIXELS in the attached screenshot (origin top-left). \
    The tag vocabulary:

    [TARGET:x,y,r:label]          ring the single next thing to CLICK (r = radius in px)
    [HOVER:x,y,r:label]           dashed ring for something to hover, not click
    [HIGHLIGHT:x,y,w,h:label]     rectangle around a region you are talking about
    [SHAPE:arrow:x1,y1,x2,y2:label]        arrow from one point to another
    [SHAPE:curve:x1,y1,cx,cy,x2,y2:label]  curved arrow through a control point
    [POINT:x,y:label]             a small labelled marker chip

    Rules: use TARGET only when there is exactly one observable next action. Labels are 1–4 words. \
    Use a handful of tags per lesson, each synced to what you are currently saying — the chips \
    accumulate on screen into a legend as you teach. If the user's request needs no drawing, just \
    answer naturally with no tags.
    """
}

// Errors surfaced by the ChatGPT transport.
enum WispChatError: LocalizedError {
    case notConnected
    case backend(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "ChatGPT is not connected — run `codex login` and relaunch Wisp."
        case .backend(let status, let body):
            return "ChatGPT backend \(status): \(body.prefix(200))"
        }
    }
}
