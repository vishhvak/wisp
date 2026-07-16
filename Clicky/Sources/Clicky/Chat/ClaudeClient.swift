import Foundation
import CoreGraphics

// One event emitted while streaming a Claude response. Spoken/displayed text arrives as `.textDelta`
// (already stripped of any inline tags), and any `[POINT:...]` / `[DRAW:...]` tag found inline is
// surfaced separately as `.teachingAnnotation` so the overlay can paint it on the user's screen.
enum ChatStreamEvent: Equatable {
    case textDelta(String)
    case teachingAnnotation(TeachingAnnotation)
}

// A screenshot to attach to a Claude request. `base64EncodedImage` is the raw base64 (no data-URL
// prefix) and `mediaType` is the corresponding IANA type (e.g. "image/png").
struct ChatImageAttachment {
    let base64EncodedImage: String
    let mediaType: String
}

// Talks to Claude through the Cloudflare Worker's /chat route (which injects the real Anthropic key
// and forwards to api.anthropic.com/v1/messages). Requests stream via Server-Sent Events; this
// client parses the SSE stream, yields text deltas, and extracts inline teaching tags.
final class ClaudeClient {

    // Streams a Claude response for `userMessageText` plus optional screenshot attachments. Returns
    // an AsyncThrowingStream of ChatStreamEvent so the caller can drive TTS/text + the overlay live.
    func streamResponse(
        userMessageText: String,
        imageAttachments: [ChatImageAttachment] = [],
        modelIdentifier: String = ClickyConfig.defaultClaudeModel
    ) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            // Run the network + parse work in a detached task so the stream returns immediately.
            let streamingTask = Task {
                do {
                    let chatRequest = try buildChatRequest(
                        userMessageText: userMessageText,
                        imageAttachments: imageAttachments,
                        modelIdentifier: modelIdentifier
                    )

                    // URLSession.bytes gives us the response body as an async sequence of lines,
                    // which is exactly the shape SSE wants (one `data:` line at a time).
                    let (byteStream, _) = try await URLSession.shared.bytes(for: chatRequest)

                    // Buffers text across deltas so a tag split across two deltas is still matched.
                    let tagExtractor = InlineTagExtractor()

                    for try await sseLine in byteStream.lines {
                        // SSE data lines look like: `data: {json}`. Ignore `event:` lines and blanks.
                        guard sseLine.hasPrefix("data:") else { continue }
                        let jsonPayload = String(sseLine.dropFirst("data:".count))
                            .trimmingCharacters(in: .whitespaces)

                        // The Anthropic stream terminates the message with a `[DONE]`-style sentinel
                        // on some proxies; treat it as end-of-stream.
                        if jsonPayload == "[DONE]" { break }

                        if let extractedTextDelta = Self.extractTextDelta(fromEventJSON: jsonPayload) {
                            // Feed the raw delta through the tag extractor, which returns clean text
                            // to speak/show plus any completed teaching annotations.
                            let extraction = tagExtractor.consume(extractedTextDelta)
                            if !extraction.cleanText.isEmpty {
                                continuation.yield(.textDelta(extraction.cleanText))
                            }
                            for annotation in extraction.annotations {
                                continuation.yield(.teachingAnnotation(annotation))
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            // If the consumer cancels the stream, cancel the underlying network task too.
            continuation.onTermination = { _ in
                streamingTask.cancel()
            }
        }
    }

    // Builds the POST request to the Worker's /chat route with an Anthropic Messages body.
    private func buildChatRequest(
        userMessageText: String,
        imageAttachments: [ChatImageAttachment],
        modelIdentifier: String
    ) throws -> URLRequest {
        let chatURL = ClickyConfig.workerBaseURL.appendingPathComponent("chat")
        var chatRequest = URLRequest(url: chatURL)
        chatRequest.httpMethod = "POST"
        chatRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Assemble the user message's content blocks: each screenshot as an image block, then the
        // spoken text as a final text block (Anthropic vision expects images before the question).
        var userContentBlocks: [[String: Any]] = []
        for imageAttachment in imageAttachments {
            userContentBlocks.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": imageAttachment.mediaType,
                    "data": imageAttachment.base64EncodedImage
                ]
            ])
        }
        userContentBlocks.append([
            "type": "text",
            "text": userMessageText
        ])

        let anthropicMessagesBody: [String: Any] = [
            "model": modelIdentifier,
            "max_tokens": 1024,
            "stream": true,
            "messages": [
                [
                    "role": "user",
                    "content": userContentBlocks
                ]
            ]
        ]

        chatRequest.httpBody = try JSONSerialization.data(withJSONObject: anthropicMessagesBody)
        return chatRequest
    }

    // Pulls the text out of a single Anthropic SSE event. We care about `content_block_delta`
    // events carrying a `text_delta`; everything else (message_start, ping, etc.) returns nil.
    private static func extractTextDelta(fromEventJSON eventJSON: String) -> String? {
        guard let eventData = eventJSON.data(using: .utf8),
              let decodedEvent = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any] else {
            return nil
        }
        guard decodedEvent["type"] as? String == "content_block_delta",
              let deltaObject = decodedEvent["delta"] as? [String: Any],
              deltaObject["type"] as? String == "text_delta",
              let deltaText = deltaObject["text"] as? String else {
            return nil
        }
        return deltaText
    }
}

// Extracts `[POINT:...]` and `[DRAW:...]` tags from a stream of text deltas, returning the "clean"
// spoken text with tags removed plus any completed TeachingAnnotation values. Because deltas can
// split a tag across chunk boundaries, this buffers any trailing partial "[" fragment and only
// emits clean text up to a point where no tag could still be forming.
final class InlineTagExtractor {
    // Holds text that might still be the start of an incomplete tag between calls.
    private var pendingBuffer = ""

    // The result of consuming one delta: clean text to speak/show, plus finished annotations.
    struct ExtractionResult {
        var cleanText: String
        var annotations: [TeachingAnnotation]
    }

    func consume(_ incomingText: String) -> ExtractionResult {
        pendingBuffer += incomingText

        var cleanTextOutput = ""
        var extractedAnnotations: [TeachingAnnotation] = []

        // Repeatedly pull complete `[...]` tags out of the buffer, emitting the text before each.
        while let openingBracketIndex = pendingBuffer.firstIndex(of: "[") {
            // Everything before the "[" is safe, tag-free text.
            cleanTextOutput += String(pendingBuffer[pendingBuffer.startIndex..<openingBracketIndex])

            guard let closingBracketIndex = pendingBuffer[openingBracketIndex...].firstIndex(of: "]") else {
                // No closing "]" yet — the tag may still be arriving. Keep from "[" onward buffered.
                pendingBuffer = String(pendingBuffer[openingBracketIndex...])
                return ExtractionResult(cleanText: cleanTextOutput, annotations: extractedAnnotations)
            }

            // We have a full `[...]`. Parse it; if it's a known tag, turn it into an annotation.
            let fullTagText = String(pendingBuffer[openingBracketIndex...closingBracketIndex])
            if let parsedAnnotation = Self.parseTag(fullTagText) {
                extractedAnnotations.append(parsedAnnotation)
            } else {
                // Unknown bracketed text — keep it in the visible/spoken output rather than dropping.
                cleanTextOutput += fullTagText
            }

            // Continue scanning after the closing bracket.
            pendingBuffer = String(pendingBuffer[pendingBuffer.index(after: closingBracketIndex)...])
        }

        // No "[" remains — the whole remaining buffer is clean text.
        cleanTextOutput += pendingBuffer
        pendingBuffer = ""
        return ExtractionResult(cleanText: cleanTextOutput, annotations: extractedAnnotations)
    }

    // Flushes any buffered text at end-of-stream (e.g. a lone "[" that never became a tag).
    func flushRemaining() -> String {
        let remaining = pendingBuffer
        pendingBuffer = ""
        return remaining
    }

    // Parses a single tag string into a TeachingAnnotation. Supported forms:
    //   [POINT:x,y:label:screenN]                         → a dot + chip at (x,y)
    //   [DRAW:rect:x,y,width,height:label:screenN]        → a stroked rectangle
    //   [DRAW:arrow:x1,y1,x2,y2:label:screenN]            → an arrow from (x1,y1) to (x2,y2)
    //   [DRAW:dot:x,y:label:screenN]                      → a dot
    // The `label` and `screenN` fields are optional; a missing screen defaults to display 0.
    private static func parseTag(_ tagText: String) -> TeachingAnnotation? {
        // Strip the surrounding brackets and split into colon-delimited fields.
        let innerText = tagText
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let fields = innerText.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard let tagKind = fields.first?.uppercased() else { return nil }

        switch tagKind {
        case "POINT":
            // [POINT:x,y:label:screenN]
            guard fields.count >= 2,
                  let point = parseCGPoint(fields[1]) else { return nil }
            let label = fields.count >= 3 ? fields[2] : ""
            let displayIndex = fields.count >= 4 ? parseScreenIndex(fields[3]) : 0
            // A POINT renders as a chip label anchored at the point (a labelled marker).
            return TeachingAnnotation(shape: .chip(point), label: label, displayIndex: displayIndex)

        case "DRAW":
            // [DRAW:shape:coords:label:screenN]
            guard fields.count >= 3 else { return nil }
            let drawShapeKind = fields[1].lowercased()
            let coordinateField = fields[2]
            let label = fields.count >= 4 ? fields[3] : ""
            let displayIndex = fields.count >= 5 ? parseScreenIndex(fields[4]) : 0

            switch drawShapeKind {
            case "rect":
                guard let rectangle = parseCGRect(coordinateField) else { return nil }
                return TeachingAnnotation(shape: .rect(rectangle), label: label, displayIndex: displayIndex)
            case "arrow":
                guard let (startPoint, endPoint) = parseTwoPoints(coordinateField) else { return nil }
                return TeachingAnnotation(shape: .arrow(from: startPoint, to: endPoint), label: label, displayIndex: displayIndex)
            case "dot":
                guard let point = parseCGPoint(coordinateField) else { return nil }
                return TeachingAnnotation(shape: .dot(point), label: label, displayIndex: displayIndex)
            default:
                return nil
            }

        default:
            return nil
        }
    }

    // Parses "x,y" into a CGPoint.
    private static func parseCGPoint(_ text: String) -> CGPoint? {
        let numbers = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count == 2 else { return nil }
        return CGPoint(x: numbers[0], y: numbers[1])
    }

    // Parses "x,y,width,height" into a CGRect.
    private static func parseCGRect(_ text: String) -> CGRect? {
        let numbers = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count == 4 else { return nil }
        return CGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
    }

    // Parses "x1,y1,x2,y2" into a start/end point pair.
    private static func parseTwoPoints(_ text: String) -> (CGPoint, CGPoint)? {
        let numbers = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard numbers.count == 4 else { return nil }
        return (CGPoint(x: numbers[0], y: numbers[1]), CGPoint(x: numbers[2], y: numbers[3]))
    }

    // Parses "screen2" (or "2") into a zero-based display index. Defaults to 0 on any parse failure.
    private static func parseScreenIndex(_ text: String) -> Int {
        let digitsOnly = text.filter(\.isNumber)
        return Int(digitsOnly) ?? 0
    }
}
