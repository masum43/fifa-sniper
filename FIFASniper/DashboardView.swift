import SwiftUI
import Combine

struct LogItem: Identifiable {
    let id = UUID()       // Unique identifier
    let text: String      // Text string
    let date: Date        // Date
}


struct DashboardView: View {
    let xUtSid: String
    
    @State private var searchQuery: String = ""
    @State private var players: [Player] = []
    @State private var selectedPlayer: Player?
    @State private var maxBuyPrice: String = ""
    @State private var sellBidPrice: String = ""
    @State private var sellBuyNowPrice: String = ""
    @State private var searchInterval: String = "200"
    @State private var isSniping: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool
    @State var intervalOptions: [String] = ["Risky","Medium","Safe"]
    @State var offerselection = -1
    @State private var text1: String = ""
    @State var shouldShow2 = false
    @State private var timer: AnyCancellable?
    @State var timerInterval: TimeInterval = 1.5
    @State var isBotStarted = false
    @State private var storePlayer: [Player] = []
    
    @State var found  = 0
    @State var search = 0
    @State var buys = 0
    @State var profit = 0
    
    @State  var texts: [LogItem] = []
    
    var body: some View {
        
        VStack {
            
            Text("FIFA Sniper Dashboard")
                .font(.system(size: 28  , weight: .bold))
                .padding(.top,10)
            HStack {
                TextField("Search players", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isInputFocused)
                
                Button("Search") {
                    searchPlayers()
                }
            }
            .padding()
            
            
            
            if selectedPlayer != nil {
                
                HStack {
                    AsyncImage(url: URL(string: selectedPlayer?.image ?? "")) { image in
                        image.resizable()
                            .clipShape(Circle())
                    } placeholder: {
                        Color.gray.clipShape(Circle())
                    }
                    .frame(width: 45, height: 45)
                    
                    VStack(alignment: .leading) { // Ensure alignment is set to leading
                        Text(selectedPlayer?.name ?? "")
                            .font(.system(size: 14)) // Optional: set font size
                            .foregroundColor(.white) // Optional: adjust text color
                        Text("\(selectedPlayer?.rating ?? 0) OVR | \(selectedPlayer?.price ?? 0) coins")
                            .font(.system(size: 10))// Optional: set font size
                        // Optional: adjust text color
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Make the VStack take full width
                }
                .frame(width: UIScreen.main.bounds.width - 40, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                )
                
                if !isBotStarted {
                    
                    VStack {
                        Text("Price Settings")
                            .font(.headline) // Title remains bold
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom)
                        HStack {
                            Text("(Snipe) Buy Now price:")
                                .frame(width: 150, alignment: .leading)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) // Border color and width
                                Color.clear // Background color
                                    .cornerRadius(5) // Match the corner radius
                                TestTextfield(text: $maxBuyPrice, placeholder: "", keyType: .numberPad)
                                    .textFieldStyle(PlainTextFieldStyle()) // No default border
                                    .keyboardType(.decimalPad)
                                    .accessibilityLabel("(Snipe) Buy Now price:")
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                // Dismiss the keyboard
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                        }
                                    }
                                    .padding(5)
                            }
                            .frame(height: 40)
                        }
                        
                        
                        
                        HStack {
                            Text("(Sell) Bid Price")
                                .frame(width: 150, alignment: .leading)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) // Border color and width
                                Color.clear // Background color
                                    .cornerRadius(5) // Match the corner radius
                                TestTextfield(text: $sellBidPrice, placeholder: "", keyType: .numberPad)
                                    .textFieldStyle(PlainTextFieldStyle()) // No default border
                                    .keyboardType(.decimalPad)
                                    .accessibilityLabel("(Sell) Bid Price")
                                    .padding(5)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                // Dismiss the keyboard
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                        }
                                    }
                            }
                            .frame(height: 40)
                        }
                        
                        
                        HStack {
                            Text("(Sell) Buy Now Price")
                                .frame(width: 150, alignment: .leading)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) // Border color and width
                                Color.clear // Background color
                                    .cornerRadius(5) // Match the corner radius
                                TestTextfield(text: $sellBuyNowPrice, placeholder: "", keyType: .numberPad)
                                    .textFieldStyle(PlainTextFieldStyle()) // No default border
                                    .keyboardType(.decimalPad)
                                    .accessibilityLabel("(Sell) Buy Now Price")
                                    .padding(5)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                // Dismiss the keyboard
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                        }
                                    }
                            }
                            .frame(height: 40)
                            
                            
                        }
                        
                        HStack {
                            Text("Search Interval (ms)")
                                .frame(width: 150, alignment: .leading)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            DropListView(placeholder: "Safe", label: "", text: $text1, options: intervalOptions, selectedIndex: offerselection,shouldShow: $shouldShow2) { index in
                                
                                
                                if index == 0 {
                                    self.timerInterval  = 1.5
                                    
                                }
                                else if index == 1 {
                                    self.timerInterval  = 2.1
                                }
                                else {
                                    self.timerInterval = 3.0
                                }
                                
                                
                            }.frame(maxWidth: 250)
                            
                            
                        }
                        
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
                    .padding()
                    
                    VStack {
                        HStack {
                            Text("Start Bot")
                                .font(.system(size: 15))
                                .padding()
                            
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .onTapGesture {
                                    print("called bot started")
                                    isBotStarted = true
                                    isSniping.toggle()
                                    if isSniping {
                                        startSniping()
                                    }
                                }
                        }
                        .frame(width: UIScreen.screenWidth - 2*20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                    }
                    .padding(.top, 10)
                }
                else {
                    
                    VStack {
                             ScrollView {
                                 LazyVStack {
                                     ForEach(texts.reversed()) { item in
                                         HStack {
                                             Text(formatter.string(from: item.date))
                                                 .font(.subheadline)
                                                 .foregroundColor(.gray)
                                             
                                             Spacer()
                                             
                                             Text(item.text)
                                                 .font(.headline)
                                         }
                                         .padding()
                                    
                                         .cornerRadius(10)
                                         .shadow(radius: 5)
                                     }
                                 }
                                 .padding()
                             }
                             .background(Color(UIColor.systemGray6))
                             .cornerRadius(10)
                             .shadow(radius: 5)
                         }
                         .padding()
                 
                    
                    VStack {
                        HStack {
                            Text("Stop Bot")
                                .font(.system(size: 15))
                                .padding()
                            
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .onTapGesture {
                                    print("called bot started")
                                    selectedPlayer = nil
                                    players = storePlayer
                                    isBotStarted = false
                                    isSniping.toggle()
                                    found  = 0
                                    search = 0
                                    buys = 0
                                    profit = 0
                                    texts.removeAll()
                                    self.stopTimer()
                                }
                        }
                        .frame(width: UIScreen.screenWidth - 2*20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red)
                        )
                    }
                    .padding(.top, 10)
                    
                    
                }
                
                if isBotStarted {
                    VStack {
                        HStack(spacing: 10) {
                            VStack(spacing: 2) { // Reduced spacing between texts
                                Text("\(search)")
                                    .font(.headline)
                                    .padding(.vertical, 4) // Reduced vertical padding
                                    .foregroundColor(.white)
                                Text("Searches")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8) // Adjusted horizontal padding
                            .background(Color.clear)
                            .cornerRadius(10)
                            
                            VStack(spacing: 2) { // Reduced spacing
                                Text("\(found)")
                                    .font(.headline)
                                    .padding(.vertical, 4)
                                    .foregroundColor(.white)
                                Text("Found")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                            .background(Color.clear)
                            .cornerRadius(10)
                            
                            VStack(spacing: 2) { // Reduced spacing
                                Text("\(buys)")
                                    .font(.headline)
                                    .padding(.vertical, 4)
                                    .foregroundColor(.white)
                                Text("Buys")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                            .background(Color.clear)
                            .cornerRadius(10)
                            
                            VStack(spacing: 2) { // Reduced spacing
                                Text("\(profit)")
                                    .font(.headline)
                                    .padding(.vertical, 4)
                                    .foregroundColor(.white)
                                Text("Profit")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                            .background(Color.clear)
                            .cornerRadius(10)
                        }
                        .padding(8) // Reduced overall padding for HStack
                        
                    }.frame(width: UIScreen.screenWidth - 2*20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                
                
            }
            else {
                
                List(players) { player in
                    Button(action: { selectPlayer(player) }) {
                        HStack {
                            AsyncImage(url: URL(string: player.image)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading) {
                                Text(player.name)
                                Text("Rating: \(player.rating)")
                            }
                        }
                    }
                }
            }
            
            
        }.frame(maxHeight: .infinity, alignment: .top)
        
        
    }
    
    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss a" // Format: Hour:Minute:Second AM/PM
        return formatter
    }
    
    private func searchPlayers() {
        APIService.shared.searchPlayers(xUtSid: xUtSid, query: searchQuery) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let players):
                    selectedPlayer = nil
                    self.errorMessage = nil
                    self.players = players
                    self.storePlayer = players
                    isInputFocused = false
                case .failure(let error):
                    self.errorMessage = "Failed to search players:"
                    selectedPlayer = nil
                    players.removeAll()
                }
            }
        }
    }
    
    private func startTimer() {
        stopTimer() // Cancel any existing timer
        
        print("timer interval: \(timerInterval)")
        timer = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { input in
                
                print("timer has been called")
                performSnipe()
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func selectPlayer(_ player: Player) {
        selectedPlayer = player
        APIService.shared.getPlayerStats(xUtSid: xUtSid, playerId: player.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    players.removeAll()
                    maxBuyPrice = "\(stats.price)"
                    sellBidPrice = "\(Int(Double(stats.price) * 1.1))"
                    sellBuyNowPrice = "\(Int(Double(stats.price) * 1.2))"
                case .failure(let error):
                    self.errorMessage = "Failed to get player stats: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startSniping() {
        self.stopTimer()
        self.startTimer()
        
    }
    
    private func performSnipe() {
        guard let player = selectedPlayer,
              let maxBuy = Int(maxBuyPrice),
              let sellBid = Int(sellBidPrice),
              let sellBuyNow = Int(sellBuyNowPrice) else {
            return
        }
        
        search = search + 1
        
        
        
        
        let bidPrices = [150, 200, 250, 300, 350, 400, 450, 500, 550, 600]
        let buyPrices = [200, 250, 300, 350, 400, 450, 500, 550, 600]
        
        // Choose random elements from the arrays
        let minBidPrice = bidPrices.randomElement()!
        let minBuyPrice = buyPrices.randomElement()!
        
        let params: [String: Any] = [
            "maskedDefId": player.id,
            "maxb": maxBuy,
            "num": 21,
            "start": 0,
            "type": "player",
            "micr": minBidPrice,
            "minb": minBuyPrice
        ]
        
        
        
        APIService.shared.searchTransferMarket(xUtSid: xUtSid, params: params) { result in
            switch result {
            case .success(let response):
                texts.append(LogItem(text: "No Aunction Found", date: Date()))
                found = found + 1
                for auction in response.auctionInfo {
                    if auction.buyNowPrice <= maxBuy {
                        
                        print("buy sell price \(auction.buyNowPrice) \(maxBuy)")
                        buyAndSellPlayer(auction: auction, sellBid: sellBid, sellBuyNow: sellBuyNow)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    
                    self.errorMessage = "Search error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func buyAndSellPlayer(auction: AuctionInfo, sellBid: Int, sellBuyNow: Int) {
        
        
        APIService.shared.buyPlayer(xUtSid: xUtSid, tradeId: auction.tradeId, bid: auction.buyNowPrice) { result in
            switch result {
            case .success(let buyResponse):
                
                print("response i got \(buyResponse)")
                if let boughtAuction = buyResponse.auctionInfo?.first {
                    DispatchQueue.main.async {
                        buys = buys + 1
                        texts.append(LogItem(text: "Found Plyer! Buying for \(boughtAuction.buyNowPrice)", date: Date()))
                    }
                    self.listPlayer(itemId: boughtAuction.itemData.id, sellBid: sellBid, sellBuyNow: sellBuyNow, boughtPrice: auction.buyNowPrice)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    texts.append(LogItem(text: "Failed to buy player", date: Date()))
                    self.errorMessage = "Buy error: \(error.localizedDescription)"
                    print("Hi = \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func listPlayer(itemId: Int, sellBid: Int, sellBuyNow: Int, boughtPrice: Int) {
        APIService.shared.listPlayer(xUtSid: xUtSid, itemData: ["id": itemId], startingBid: sellBid, buyNowPrice: sellBuyNow, duration: 3600) { result in
            switch result {
            case .success(_):
                let profit = sellBuyNow - boughtPrice - Int(Double(sellBuyNow) * 0.05)
                DispatchQueue.main.async {
                    self.profit = profit + 1
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "List error: \(error.localizedDescription)"
                }
            }
        }
    }
}



struct DropListView: View {
    let placeholder: String
    let label: String
    @Binding var text: String
    
    @State var options: [String]
    @State var selectedIndex: Int
    @Binding var shouldShow:Bool
    var optionSelected: ((Int) -> Void)? //
    @State var finalText = ""
    
    
    var body: some View {
        VStack {
            Menu {
                ForEach(0..<options.count) { index in
                    let option = options[index]
                    Button(action: {
                        selectedIndex = index
                        optionSelected?(index)
                        
                    }) {
                        Text(option)
                    }
                }
            } label: {
                HStack {
                    if shouldShow {
                        Spacer()
                    }
                    Text(selectedIndex >= 0 ? options[selectedIndex] : finalText)
                        .background(Color.clear)
                        .foregroundColor(Color.white)
                        .font(.system(size: 15))
                        .onAppear {
                            finalText = getText()
                        }
                    
                    
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down").foregroundColor(Color.gray)
                }
            }
            .padding()
            .background(Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    
    func getText() -> String {
        
        if  options.count < 1  {
            return label
        }
        text = selectedIndex == -1 ? "\(placeholder)" : options[selectedIndex]
        return selectedIndex == -1 ? "\(placeholder)" : options[selectedIndex]
    }
}


struct TestTextfield: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyType: UIKeyboardType
    func makeUIView(context: UIViewRepresentableContext<TestTextfield>) -> UITextField {
        let textfield = UITextField()
        textfield.keyboardType = keyType
        textfield.placeholder = placeholder
        textfield.text = text
        textfield.delegate = context.coordinator
        textfield.textColor  = UIColor.white
        textfield.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: textfield.frame.size.width, height: 44))
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(textfield.doneButtonTapped(button:)))
        toolBar.items = [flexSpace,doneButton]
        toolBar.setItems([flexSpace,doneButton], animated: true)
        textfield.inputAccessoryView = toolBar
        return textfield
    }
    
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<TestTextfield>) {
        print("updateUIView()")
        uiView.text = text
        
    }
    
    func makeCoordinator() -> TestTextfield.Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TestTextfield
        
        init(parent: TestTextfield) {
            print("init(parent: TestTextfield)")
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            print("textFieldDidChangeSelection: \(String(describing: textField.text))")
        }
    }
}

extension  UITextField{
    @objc func doneButtonTapped(button:UIBarButtonItem) -> Void {
        self.resignFirstResponder()
    }
    
}

extension  UITextView{
    @objc func doneButtonTapped(button:UIBarButtonItem) -> Void {
        self.resignFirstResponder()
    }
    
}
