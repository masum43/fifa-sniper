import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://utas.mob.v4.prd.futc-ext.gcp.ea.com/ut/game/fc25"
    
    private init() {}
    
    private func getEAHeaders(xUtSid: String) -> [String: String] {
        return [
            "Host": "utas.mob.v4.prd.futc-ext.gcp.ea.com",
            "Sec-Ch-Ua": "\"Not;A=Brand\";v=\"24\", \"Chromium\";v=\"128\"",
            "X-Ut-Sid": xUtSid,
            "Sec-Ch-Ua-Platform": "Windows",
            "Accept-Language": "en-US,en;q=0.9",
            "Sec-Ch-Ua-Mobile": "?0",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.120 Safari/537.36",
            "Accept": "*/*",
            "Origin": "https://www.ea.com",
            "Sec-Fetch-Site": "same-site",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Referer": "https://www.ea.com/",
            "Accept-Encoding": "gzip, deflate, br",
            "Priority": "u=1, i",
            "Connection": "keep-alive"
        ]
    }
    
    func login(xUtSid: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/transfermarket") else {
            completion(.failure(LoginError.unexpectedError("Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getEAHeaders(xUtSid: xUtSid)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for a network error
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check the HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    // Handle successful login
                    completion(.success(true))
                case 401:
                    completion(.failure(LoginError.expiredSession))
                case 426, 521, 429, 512:
                    completion(.failure(LoginError.transferMarketBanned))
                case 458:
                    completion(.failure(LoginError.captchaRequired))
                default:
                    completion(.failure(LoginError.unexpectedError("Unexpected error: \(httpResponse.statusCode)")))
                }
            } else {
                // Handle cases where the response is not an HTTP URL response
                completion(.failure(LoginError.unexpectedError("No valid HTTP response received")))
            }
        }.resume()
    }
    
    func searchPlayers(xUtSid: String, query: String, completion: @escaping (Result<[Player], Error>) -> Void) {
        let url = URL(string: "https://www.fut.gg/api/fut/players/v2/search/?name=\(query)")!
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // make sure this JSON is in the format we expect
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("find \(json)")
                    
                    
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlayerSearchResponse.self, from: data)
                let players = response.data.prefix(5).map { playerData in
                    Player(id: playerData.basePlayerEaId,
                           name: "\(playerData.firstName) \(playerData.lastName)",
                           rating: playerData.overall,
                           price: 0,
                           image: "https://game-assets.fut.gg/\(playerData.imagePath)",
                           clubImage: "https://game-assets.fut.gg/\(playerData.club.imagePath)")
                }
                completion(.success(Array(players)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getPlayerStats(xUtSid: String, playerId: Int, completion: @escaping (Result<PlayerStats, Error>) -> Void) {
        let url = URL(string: "https://www.fut.gg/api/fut/player-prices/25/?ids=\(playerId)")!
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlayerStatsResponse.self, from: data)
                if let playerData = response.data.first {
                    let stats = PlayerStats(price: playerData.price ?? 0, extinct: playerData.isExtinct ?? false)
                    completion(.success(stats))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No player data found"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func searchTransferMarket(xUtSid: String, params: [String: Any], completion: @escaping (Result<TransferMarketResponse, Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/transfermarket")!
        urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        
        var request = URLRequest(url: urlComponents.url!)
        request.allHTTPHeaderFields = getEAHeaders(xUtSid: xUtSid)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TransferMarketResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func buyPlayer(xUtSid: String, tradeId: Int, bid: Int, completion: @escaping (Result<BuyPlayerResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/trade/\(tradeId)/bid")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getEAHeaders(xUtSid: xUtSid)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONEncoder().encode(["bid": bid])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Deserialize the JSON
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                
                
            } catch {
                
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BuyPlayerResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func listPlayer(xUtSid: String, itemData: [String: Int], startingBid: Int, buyNowPrice: Int, duration: Int, completion: @escaping (Result<ListPlayerResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/auctionhouse")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getEAHeaders(xUtSid: xUtSid)
        request.httpMethod = "POST"
        
        let body = [
            "itemData": itemData,
            "startingBid": startingBid,
            "buyNowPrice": buyNowPrice,
            "duration": duration
        ] as [String : Any]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ListPlayerResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Data Models

struct Player: Identifiable {
    let id: Int
    let name: String
    let rating: Int
    let price: Int
    let image: String
    let clubImage: String
}

struct PlayerStats {
    let price: Int
    let extinct: Bool
}

struct PlayerSearchResponse: Codable {
    let data: [PlayerData]
}

struct PlayerData: Codable {
    let basePlayerEaId: Int
    let firstName: String
    let lastName: String
    let overall: Int
    let imagePath: String
    let club: ClubData
}

struct ClubData: Codable {
    let imagePath: String
}

struct PlayerStatsResponse: Codable {
    let data: [PlayerStatsData]
}

struct PlayerStatsData: Codable {
    let price: Int?
    let isExtinct: Bool?
}

struct TransferMarketResponse: Codable {
    let auctionInfo: [AuctionInfo]
}

struct AuctionInfo: Codable {
    let tradeId: Int
    let buyNowPrice: Int
    let startingBid: Int
    let currentBid: Int
    let expires: Int
    let itemData: ItemData
}

struct ItemData: Codable {
    let id: Int
    let timestamp: Int
}

struct BuyPlayerResponse: Codable {
    let auctionInfo: [AuctionInfo]?
}

struct ListPlayerResponse: Codable {
    let id: Int
    let idStr: String
}
