//
//  ContentView.swift
//  Sample61_GeocodeMap
//
//  Created by keiji yamaki on 2022/01/21.
//

import SwiftUI
import CoreLocation
import MapKit

// 検索画面のタイプ
enum SearchViewType: Int {
    case initial = 0    // 初期画面
    case detail = 1     // 詳細画面
    case suggest = 2    // 候補画面
}
struct ContentView: View {
    @State var manager = CLLocationManager()
    @State var addressName: String = ""
    @State var alert = false
    @State var mapBind: MKMapView?
    @State var searchViewType: SearchViewType = .initial    // 検索画面のタイプ：初期画面
    @State var mapSuggestItems: [MKMapItem] = []    // マップ候補リスト
    
    var body: some View {
        HStack {
            // ジャンル選択
            if searchViewType == .initial {
                Button("ジャンル"){
                    print("ジャンル")
                }
            }
            // 場所入力
            TextField("行きたい場所を入力", text: $addressName,
                onEditingChanged: {changed in
                    // 検索詳細画面を表示
                    searchViewType = .detail
                },
                onCommit: {
                    // 場所の検索
                    searchSpot()
                })
                .modifier(ClearButton(text: $addressName))
                .padding(.all, 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue, lineWidth: 2)
                ).padding(.all, 5)
            // 距離
            if searchViewType == .initial {
                Button("5km"){
                    print("距離")
                }
            }
            // キャンセル
            if searchViewType != .initial {
                Button("キャンセル"){
                    // 初期画面に戻す
                    searchViewInit()
                }
            }
        }
        ZStack(alignment: .top) {
            // 地図の表示
            MapView(mapBind: $mapBind).alert(isPresented: $alert) {
                Alert(title: Text("Please Enable Location Access In Setting Panel!!!"))
            }
            // 検索詳細画面の表示
            if searchViewType == .detail {
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
            // 検索候補の表示
            else if searchViewType == .suggest {
                List {
                    ForEach(mapSuggestItems, id: \.self) { mapItem in
                        if let name = mapItem.name {
                            Text(name)
                                .onTapGesture{
                                    // タップで、位置を表示
                                    showSpot(mapItem: mapItem)
                                    // 文字列を設定
                                    addressName = name
                                }
                        }
                    }
                }.background(Color.white)
            }
        }
    }
    // 場所の検索
    func searchSpot(){
        if let region = mapBind?.region {
            mapSearch(query: addressName, region: region){ response in
                // ２個以上の場合は、候補を表示
                if response.count > 1 {
                    self.mapSuggestItems = response
                    searchViewType = .suggest
                    // suggestOn = true
                }else if response.count == 1 {
                    showSpot(mapItem: response[0])
                }
            }
        }
    }
    // 検索画面の初期設定
    func searchViewInit(){
        // 編集状態をキャンセル
        UIApplication.shared.endEditing()
        // 検索画面を初期画面に
        searchViewType = .initial
    }
    // 検索場所の表示
    func showSpot(mapItem: MKMapItem){
        let coordinate = mapItem.placemark.coordinate
        mapBind!.setCenter(coordinate, animated: true)
        // 初期画面に戻す
        searchViewInit()
    }
    // 地図の検索
    func mapSearch(query: String, region: MKCoordinateRegion? = nil, completion: (([MKMapItem]) -> Void)?) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let region = region {
            request.region = region
        }

        MKLocalSearch(request: request).start { (response, error) in
            if let error = error {
                completion!([])
                return
            }
            completion!(response?.mapItems ?? [])
        }
    }
}
struct MapView: UIViewRepresentable {
    @Binding var mapBind: MKMapView?
    
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
