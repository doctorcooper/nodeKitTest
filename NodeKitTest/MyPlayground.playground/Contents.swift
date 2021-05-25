import UIKit
import NodeKit

var baseURL = URL(string: "https://sentim-api.herokuapp.com")

enum Routes: UrlRouteProvider {
    case path
    
    func url() throws -> URL {
        switch self {
        case .path:
            return try baseURL + "/api/v1/"
        }
    }
}

// MARK: - Сущности для отправки
struct TextEntry: Codable, RawEncodable {
    typealias Raw = Json
    
    let text: String
}

struct TextEntity: DTOEncodable {
    let text: String
    
    func toDTO() throws -> TextEntry {
        return .init(text: self.text)
    }
}


// MARK: - Сущности для приема
enum SentenceCheckTypeEntry: String, Codable, RawDecodable {
    typealias Raw = Json
    
    case positive
    case neutral
    case negative
}

enum SentenceCheckTypeEntity: String, DTODecodable {
    case positive
    case neutral
    case negative
    
    static func from(dto: SentenceCheckTypeEntry) throws -> SentenceCheckTypeEntity {
        return .init(rawValue: dto.rawValue)! // Опасно. Спросить, как в таких случаях лучше действовать.
    }
}

struct SentenceCheckResultEntry: Codable, RawDecodable {
    typealias Raw = Json
    
    let polarity: Float
    let type: SentenceCheckTypeEntry
}

struct SentenceCheckResultEntity: DTODecodable {
    let polarity: Float
    let type: SentenceCheckTypeEntity
    
    static func from(dto: SentenceCheckResultEntry) throws -> SentenceCheckResultEntity {
        return try .init(polarity: dto.polarity, type: .from(dto: dto.type))
    }
}

struct SentenceEntry: Codable, RawDecodable {
    typealias Raw = Json
    
    let sentence: String
    let sentiment: SentenceCheckResultEntry
}

struct SentenceEntity: DTODecodable {
    let sentence: String
    let sentiment: SentenceCheckResultEntity
    
    static func from(dto: SentenceEntry) throws -> SentenceEntity {
        return try .init(sentence: dto.sentence, sentiment: .from(dto: dto.sentiment))
    }
}

struct SentenceResponseEntry: Codable, RawDecodable {
    typealias Raw = Json
    
    let result: SentenceCheckResultEntry
    let sentences: [SentenceEntry]
}

struct SentenceResponseEntity: DTODecodable {
    
    let result: SentenceCheckResultEntity
    let sentences: [SentenceEntity]
    
    static func from(dto: SentenceResponseEntry) throws -> SentenceResponseEntity {
        return try .init(result: .from(dto: dto.result), sentences: .from(dto: dto.sentences))
    }
}

class SentimService {
    var builder = UrlChainsBuilder<Routes>()
    let headers = ["Accept": "application/json", "Content-Type": "application/json"]
    
    func check(text: String) -> Observer<SentenceResponseEntity> {
        let textModel = TextEntity(text: text)
        
        return builder
            .route(.post, .path)
            .set(metadata: headers)
            .build()
            .process(textModel)
    }
}

let service = SentimService()
let text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."

service.check(text: text)
    .onCompleted { result in
        print(result.result)
    }
    .onError { error in
        print(error)
    }



