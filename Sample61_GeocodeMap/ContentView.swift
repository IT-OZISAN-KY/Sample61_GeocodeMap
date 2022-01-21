//
//  ContentView.swift
//  Sample61_GeocodeMap
//
//  Created by keiji yamaki on 2022/01/21.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @State var manager = CLLocationManager()
    @State var addressName: String = ""
    @State var alert = false
    @State var mapBind: MKMapView?
    @State var suggestOn = false
    @State var mapItems: [MKMapItem] = []
    
    var body: some View {
        // 場所入力
        TextField("行きたい場所を入力", text: $addressName, onCommit: {
            print("場所＝\(addressName)")
            // MKLocalSearchの場合
            if let region = mapBind?.region {
                mapSearch(query: addressName, region: region){ response in
                    // ２個以上の場合は、候補を表示
                    if response.count > 1 {
                        self.mapItems = response
                        suggestOn = true
                    }else if response.count == 1 {
                        showSpot(mapItem: response[0])
                    }
                }
            }
            // geocodeAddressStringの場合
            /*
            CLGeocoder().geocodeAddressString(addressName) { placemarks, error in
                if let lat = placemarks?.first?.location?.coordinate.latitude,
                   let lng = placemarks?.first?.location?.coordinate.longitude
                {
                    if mapBind != nil {
                        mapBind!.setCenter(CLLocationCoordinate2D(latitude: lat, longitude: lng), animated: true)
                        print("緯度 : \(lat)")
                        print("経度 : \(lng)")
                    }
                }
            }
             */
        }).padding(.all, 5)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.blue, lineWidth: 2)
            ).padding(.all, 5)
        ZStack(alignment: .top) {
            // 地図の表示
            MapView(mapBind: $mapBind).alert(isPresented: $alert) {
                Alert(title: Text("Please Enable Location Access In Setting Panel!!!"))
            }
            // 検索候補の表示
            if suggestOn {
                List {
                    ForEach(mapItems, id: \.self) { mapItem in
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
    // 検索場所の表示
    func showSpot(mapItem: MKMapItem){
        let coordinate = mapItem.placemark.coordinate
        mapBind!.setCenter(coordinate, animated: true)
        suggestOn = false
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
