import Foundation

class Game: Codable {
    var id: UUID
    var data: GameData
    var userOwner: User
    
    internal init(id: UUID, data: GameData, userOwner: User) {
        self.id = id
        self.data = data
        self.userOwner = userOwner
    }

    class Public: Codable {
        var gameID: String
        var userOwnerName: String
        var turn: Int
        var createdAt: String
        
        init(gameID: String, userOwnerName: String, turn: Int, createdAt: String) {
            self.gameID = gameID
            self.userOwnerName = userOwnerName
            self.turn = turn
            self.createdAt = createdAt
        }
    }
    final class UUIDOnly: Codable {
        var gameID: UUID
        init(gameID: UUID) {
            self.gameID = gameID
        }
    }
}
