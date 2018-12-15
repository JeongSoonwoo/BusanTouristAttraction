//
//  TableViewController.swift
//  DynamicBusan
//
//  Created by 정순우 on 2017. 12. 15..
//  Copyright © 2017년 정순우. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class TotalMapViewController: UIViewController, CLLocationManagerDelegate, XMLParserDelegate, MKMapViewDelegate  {
    
    @IBOutlet weak var myMapView: MKMapView!
    
    
    var item:[String:String] = [:]
    var tItems:[[String:String]] = []
    var key = ""
    var servieKey = "yDiLmalCzWpsaoeTpkwBgxGTwleQQIDv6Wnrne98wO5fQCserlsYGM7nfwJl%2FdYK3dUWTedo0Hphsi9GucgcKA%3D%3D"
    var listEndPoint = "http://apis.data.go.kr/6260000/BusanTourInfoService/getTouristAttrList"
    let detailEndPoint = "http://apis.data.go.kr/6260000/BusanTourInfoService/getTouristAttDetail"
    
    var totalCount = 0 //총 갯수를 저장하는 변수
    
    var locationManager: CLLocationManager!
    var lat = ""
    var long = ""
    
    var annotations = [MKAnnotation]()
    
    //========
    
//    var annotation: AnnotationData?
//    var annotations: Array = [AnnotationData]()
//    var name: String?
//    var subTitle: String?
//    var useTime: String?
//    var Tel: String?
//    var dLat: Double?
//    var dLong: Double?
//    var lat: String?
//    var long: String?
    
    //========
    
    
    
    func getList(numOfRows:Int) { //numOfRows를 입력
        //let str = detailEndPoint + "?serviceKey=\(servieKey)&numsofRows=20"
        let str = listEndPoint + "?serviceKey=\(servieKey)&numOfRows=\(numOfRows)"
        
        print(str)
        
        if let url = URL(string: str) {
            if let parser = XMLParser(contentsOf: url) {
                parser.delegate = self
                let success = parser.parse()
                if success {
                    print("parse success in getList")
                    print("totalCount = \(totalCount)")
                    
                } else {
                    print("parse failed in getList")
                }
            }
        }
    }
    
    func getDetail(dataSid: String) {
        let str = detailEndPoint + "?serviceKey=\(servieKey)&data_sid=\(dataSid)"
        
        if let url = URL(string: str) {
            if let parser = XMLParser(contentsOf: url) {
                parser.delegate = self
                let success = parser.parse()
                if success {
                    print("parse success in getDetail")
                    //print(items)
                    
                    
                } else {
                    print("parse fail in getDeatil")
                }
            }
        }
    }
    
    //*******새로 추가된 함수 - 목록데이터를 가지고 상세데이터를 가져와서 저장하는 함수
    // Detail Data 가져오는 부분을 saveDetail 메소드로 extract
    func saveDetail(url:URL) {
        let tempItems = tItems  // tableView에서 재활용
        //print("items = \(items)")
        
        tItems = []
        //-----------------thread controll----------------------
        //-------DispatchQueue선언(멀티 thread)-------------------
        //qos 속성에 따라 우선순위 변경
        let equeue = DispatchQueue(label:"com.my.queue", qos:DispatchQoS.userInitiated)
        //-------xml parxer(background thread사용)---------------
        equeue.async {
            for dic in tempItems {
                // 상세 목록 파싱
                if dic["dataSid"] == nil || dic["dataSid"] == nil || dic["dataSid"] == "-" || dic["dataSid"] == "-"{
                    
                }else{
                    self.getDetail(dataSid: dic["dataSid"]!)
                }
                //-------tableview(main thread사용(ui는 main thread 사용 필수))---
                DispatchQueue.main.async {
                    self.myMapView.reloadInputViews()
                   
                    let temp = self.tItems as NSArray  // NSArry는 화일로 저장하기 위함
                    temp.write(to: url, atomically: true)
                }
            }
        }
        //-----------------thread controll------------------------
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        //key = elementName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        key = elementName
        if key == "item" {
            item = [:]
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        // foundCharacters가 두번 호출
        if item[key] == nil {
            item[key] = string.trimmingCharacters(in: .whitespaces)
            //print("item(\(key)) = \(item[key])")
            
            //*******key가 totalCount 이면 totalCount 변수에 저장
            if key == "totalCount" {
                totalCount = Int(string.trimmingCharacters(in: .whitespaces))!
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            tItems.append(item)
        }
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "부산 관광 명소"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        myMapView.delegate = self
        viewMap()
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("mapdata.plist")
        
        //print(url)
        
        //시작할때마다 TotalCount를 받아옴
        getList(numOfRows: 0)
        
        if fileManager.fileExists(atPath: (url?.path)!) {
            //파일이 있으면 파일에서 읽어옴
            tItems = NSArray(contentsOf: url!) as! Array
            
            //파일에서 읽어본 갯수와 totalCount를 비교
            if (tItems.count != totalCount) {
                //파일에서 읽어본 갯수와 totalCount가 다르면(변화가 있으면) 다시 읽어와서 저장
                getList(numOfRows: totalCount)
                saveDetail(url: url!)
            }
        } else {
            //******* 파일이 없으면
            getList(numOfRows: totalCount)
            saveDetail(url: url!)
        }
        
        self.myMapView.addAnnotations(annotations)
        viewMap()
        
        
        
        
        
    }
    
    
    func viewMap() {
        //현재위치 트랙킹
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        //map에 현재위치 표시
        myMapView.showsUserLocation = true
        
        //var annos = [MKPointAnnotation]()
        
        for item in tItems {
            let annotation = MKPointAnnotation()
            if item["wgsx"] == nil || item["wgsy"] == nil{
                lat = "35.162685"
                long = "129.083200"
                
            }else{
                lat = item["wgsx"]!
                long = item["wgsy"]!
            }
            
            let fLat = (lat as NSString).doubleValue
            let fLong = (long as NSString).doubleValue
            
            
            annotation.coordinate.latitude = fLat
            annotation.coordinate.longitude = fLong
            annotation.title = item["dataTitle"]
            annotation.subtitle = item["addr"]
            
            annotations.append(annotation)

        }

        self.myMapView.showAnnotations(annotations, animated: true)
        self.myMapView.addAnnotations(annotations)
        //myMapView.selectAnnotation(annos[0], animated: true)
        
        zoomToRegion()
        
    }
    
    
    func zoomToRegion() {
        // 35.162685, 129.064238
        let center = CLLocationCoordinate2DMake(35.162685, 129.083200)
        //let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.44)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.44))
        myMapView.setRegion(region, animated: true)
    }
    
    
    
    func mapView(_ myMapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let reuseID = "RE"
        var annotationView = myMapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        if annotation is MKUserLocation {
            return nil
        }

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            annotationView!.canShowCallout = true
            annotationView?.animatesWhenAdded = true
            annotationView?.clusteringIdentifier = "CL"
        } else {
            annotationView?.annotation = annotation
        }

        let btn = UIButton(type: .detailDisclosure)
        annotationView?.rightCalloutAccessoryView = btn
        return annotationView


    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let capital = view.annotation as! MKPointAnnotation
        let placeName = capital.title
        let placeInfo = capital.subtitle
    
        let ac = UIAlertController(title: placeName, message: placeInfo, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        //ac.addAction(<#T##action: UIAlertAction##UIAlertAction#>)
        present(ac, animated: true)
        
        
        
//        if control == view.rightCalloutAccessoryView {
//            performSegue(withIdentifier: "DetailView", sender: self)
//        }
        
        
//        func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//            // Get the new view controller using segue.destinationViewController.
//            // Pass the selected object to the new view controller.
//
//            if segue.identifier == "DetailView" {
//                let detailMVC = segue.destination as! DetailViewController
//                let selectedAnnotation = view.annotation as! MKPointAnnotation
//
//                detailMVC.sItem = tItems[(selectedAnnotation.index(ofAccessibilityElement: annotations))]
//
//                print(tItems)
//            }
        }
        
        
        
    
    
        
    @IBAction func current(_ sender: Any) {
        let userLocation = myMapView.userLocation
        let region = MKCoordinateRegion(center: (userLocation.location?.coordinate)!, latitudinalMeters: 3000, longitudinalMeters: 3000)
        myMapView.setRegion(region, animated: true)
    }
    @IBAction func zoomIn(_ sender: Any) {
        print("zoom in pressed")
        var r = myMapView.region
        r.span.latitudeDelta = r.span.latitudeDelta / 2
        r.span.longitudeDelta = r.span.longitudeDelta / 2
        self.myMapView.setRegion(r, animated: true)
    }
    @IBAction func zoomOut(_ sender: Any) {
        print("zoom out pressed")
        var r = myMapView.region
        r.span.latitudeDelta = r.span.latitudeDelta * 2
        r.span.longitudeDelta = r.span.longitudeDelta * 2
        self.myMapView.setRegion(r, animated: true)
    }
    
    func checkLcationServiceAuthenticationStatus()
    {
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            myMapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
            
        } else {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLcationServiceAuthenticationStatus()
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//
//        if segue.identifier == "DetailView" {
//            let detailMVC = segue.destination as! DetailViewController
//            let selectedAnnotation = view.anntatio
//
//            detailMVC.sItem = tItems[(selectedAnnotation?.isSelected)!]
//        }
//
//        if segue.identifier == "goTotalMap" {
//            let totalMVC = segue.destination as! TotalMapViewController
//            totalMVC.tItems = items
//
//        } else if segue.identifier == "goSingleMap" {
//            let singleMTVC = segue.destination as! SingleMapTableViewController
//            let selectedIndex = tableView.indexPathForSelectedRow
//            singleMTVC.sItem = items[(selectedIndex?.row)!]

        }
    
    
    

    
    // MARK: - Table view data source
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return items.count
//    }
//
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        // Configure the cell...
//        let cell = tableView.dequeueReusableCell(withIdentifier: "RE", for: indexPath)
//
//        let dic = items[indexPath.row]
//        cell.textLabel?.text = dic["dataTitle"]
//        cell.detailTextLabel?.text = dic["addr"]
//
//        return cell
//    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//
//        if segue.identifier == "goTotalMap" {
//            let totalMVC = segue.destination as! TotalMapViewController
//            totalMVC.tItems = items
//
//        } else if segue.identifier == "goSingleMap" {
//            let singleMTVC = segue.destination as! SingleMapTableViewController
//            let selectedIndex = tableView.indexPathForSelectedRow
//            singleMTVC.sItem = items[(selectedIndex?.row)!]
//
//        }
//    }

