//
//  ContentView.swift
//  Sample61_GeocodeMap
//
//  Created by keiji yamaki on 2022/01/21.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine

// 検索画面のタイプ
enum SearchViewType: Int {
    case initial = 0    // 初期画面
    case detail = 1     // 詳細画面
    case suggest = 2    // 候補画面
}
struct ContentView: View {
    @State var manager = CLLocationManager()
    @State var searchString: String = ""            // 検索文字列
    @State var alert = false
    @State var mapBind: MKMapView?
    @State var mapSuggestItems: [MKMapItem] = []    // マップ候補リスト
    @ObservedObject var locationSearchService: LocationSearchService
    
    var body: some View {
        HStack {
            // ジャンル選択
            if locationSearchService.searchViewType == .initial {
                Button("ジャンル"){
                    print("ジャンル")
                }
            }
            // 場所入力
            SearchBar(locationSearchService: locationSearchService)
            // 距離
            if locationSearchService.searchViewType == .initial {
                Button("5km"){
                    print("距離")
                }
            }
            // キャンセル
            if locationSearchService.searchViewType != .initial {
                Button("キャンセル"){
                    // 初期画面に戻す
                    searchViewInit()
                }
            }
        }
        ZStack(alignment: .top) {
            // 地図の表示
            MapView(mapBind: $mapBind, locationSearchService: locationSearchService).alert(isPresented: $alert) {
                Alert(title: Text("Please Enable Location Access In Setting Panel!!!"))
            }
            // 検索詳細画面の表示
            if locationSearchService.searchViewType == .detail {
                SearchDetailView
            }
            // 検索候補の表示
            else if locationSearchService.searchViewType == .suggest {
                SearchSuggestView
            }
        }
    }
    // 検索詳細画面
    var SearchDetailView: some View {
        List {
            Text("現在地から探す >")
                .onTapGesture{
                    // 初期画面に戻す
                    searchViewInit()
                }
            Text("テーマから探す >")
                .onTapGesture{
                    // 初期画面に戻す
                    searchViewInit()
                }
            Text("エリアから探す >")
                .onTapGesture{
                    // 初期画面に戻す
                    searchViewInit()
                }
        }
    }
    // 検索候補画面
    var SearchSuggestView: some View {
        List(locationSearchService.completions) { completion in
            VStack(alignment: .leading) {
                Text(completion.title)
                Text(completion.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }.onTapGesture{
                let request = MKLocalSearch.Request(completion: completion)
                MKLocalSearch(request: request).start { (response, error) in
                    if  error != nil{
                        return
                    }
                    // 場所の検索
                    if response?.mapItems != nil && response!.mapItems.count > 0 {
                        let coordinate = response!.mapItems[0].placemark.coordinate
                        mapBind!.setCenter(coordinate, animated: false)
                    }
                }
                // 初期画面に戻す
                searchViewInit()
            }
        }.navigationBarTitle(Text("Search near me"))
    }
    // 検索画面の初期設定
    func searchViewInit(){
        // 編集状態をキャンセル
        UIApplication.shared.endEditing()
        // 検索画面を初期画面に
        locationSearchService.searchViewType = .initial
    }
}
struct MapView: UIViewRepresentable {
    @Binding var mapBind: MKMapView?
    @ObservedObject var locationSearchService: LocationSearchService    // マップ検索
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator      // マップ機能
        return map
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let coordinate = CLLocationCoordinate2D(
            latitude: 35.655164046, longitude: 139.740663704)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)
    }
    // ロケーションとマップの内部処理
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
            super.init()
        }
        // MAPのロード後
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            parent.mapBind = mapView
            // マップの検索に設定
            parent.locationSearchService.mapView = mapView
        }
    }
}
// 編集を終了
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
// クリアボタン
struct ClearButton: ViewModifier
{
    @Binding var text: String

    public func body(content: Content) -> some View
    {
        ZStack(alignment: .trailing)
        {
            content

            if !text.isEmpty
            {
                Button(action:
                {
                    self.text = ""
                })
                {
                    Image(systemName: "delete.left")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                }
                .padding(.trailing, 8)
            }
        }
    }
}
// 検索バー画面
struct SearchBar: UIViewRepresentable {
    // 引数
    @ObservedObject var locationSearchService: LocationSearchService    // ローカル検索
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @ObservedObject var locationSearchService: LocationSearchService
        // 初期化
        init(locationSearchService: LocationSearchService) {
            self.locationSearchService = locationSearchService
        }
        // テキストの変更
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            // 検索文字列を設定
            locationSearchService.searchQuery = searchText
            // 候補画面を表示
            if locationSearchService.searchViewType != .suggest {
                locationSearchService.searchViewType = .suggest
            }
        }
        // フォーカス設定
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            // 検索詳細画面を表示
            if locationSearchService.searchViewType != .detail {
                locationSearchService.searchViewType = .detail
            }
            // 検索範囲を設定
            if let region = locationSearchService.mapView?.region {
                locationSearchService.setRegion(region: region)
            }
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(locationSearchService: locationSearchService)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = locationSearchService.searchQuery
    }
}

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    var completer: MKLocalSearchCompleter
    @Published var completions: [MKLocalSearchCompletion] = []
    var cancellable: AnyCancellable?
    @Published var searchViewType: SearchViewType = .initial    // 検索画面のタイプ：初期画面
    var mapView: MKMapView?     // マップデータ
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        cancellable = $searchQuery.assign(to: \.queryFragment, on: self.completer)
        completer.delegate = self
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    // 範囲の設定
    func setRegion(region: MKCoordinateRegion) {
        completer.region = region
    }
}

extension MKLocalSearchCompletion: Identifiable {}
