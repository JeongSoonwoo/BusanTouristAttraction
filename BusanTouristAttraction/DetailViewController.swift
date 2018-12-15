//
//  DetailViewController.swift
//  BusanTouristAttraction
//
//  Created by 정순우 on 14/12/2018.
//  Copyright © 2018 정순우. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Contacts

class DetailViewController: UITableViewController, CLLocationManagerDelegate {
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet var myTableView: UITableView!
    
    @IBOutlet weak var sMealDay: UITableViewCell!
    @IBOutlet weak var sTarget: UITableViewCell!
    @IBOutlet weak var sManageNm: UITableViewCell!
    @IBOutlet weak var sPhone: UITableViewCell!
    
    var sItem:[String:String] = [:]
    var sLat: Double?
    var sLong: Double?
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 현재 위치 트랙킹
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // 지도에 현재 위치 마크를 보여줌
        myMapView.showsUserLocation = true
        
        sLat = (sItem["wgsx"]! as NSString).doubleValue
        sLong = (sItem["wgsy"]! as NSString).doubleValue
        
        let sLoc = sItem["dataTitle"]
        let sAddr = sItem["addr"]
        
        zoomToRegion()
        
        let anno = MKPointAnnotation()
        anno.coordinate.latitude = sLat!
        anno.coordinate.longitude = sLong!
        anno.title = sLoc
        anno.subtitle = sAddr
        
        myMapView.addAnnotation(anno)
        myMapView.selectAnnotation(anno, animated: true)
        
        self.title = sLoc
        sMealDay.textLabel?.text = "장소명"
        sMealDay.detailTextLabel?.text = sItem["dataTitle"]
        sTarget.textLabel?.text = "위치정보"
        sTarget.detailTextLabel?.text = sItem["addr"]
        sManageNm.textLabel?.text = "이용시간"
        sManageNm.detailTextLabel?.text = sItem["usetime"]
        sPhone.textLabel?.text = "문의전화"
        sPhone.detailTextLabel?.text = sItem["tel"]
    }
    
    func zoomToRegion() {
        // 35.162685, 129.064238
        let center = CLLocationCoordinate2DMake(sLat!, sLong!)
        let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
        let region = MKCoordinateRegion(center: center, span: span)
        myMapView.setRegion(region, animated: true)
    }
    
    // 콘솔(print)로 현재 위치 변화 출력
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coor = manager.location?.coordinate
        //print("latitute" + String(describing: coor?.latitude) + "/ longitude" + String(describing: coor?.longitude))
    }
    
    
    @IBAction func navi(_ sender: Any) {
        
        let latitude:CLLocationDegrees = sLat!
        let longitude:CLLocationDegrees = sLong!
        
        let addressDictionary = [String(CNPostalAddressStreetKey) : sItem["addr"]]
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(sItem["dataTitle"]) \(sItem["addr"])"
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    
    /*
     // MARK: - Table view data source
     
     override func numberOfSections(in tableView: UITableView) -> Int {
     // #warning Incomplete implementation, return the number of sections
     return 1
     }
     
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     // #warning Incomplete implementation, return the number of rows
     return 3
     }
     
     
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "RE", for: indexPath)
     
     // Configure the cell...
     cell.textLabel?.text = "급식일"
     cell.detailTextLabel?.text = sItem["mealDay"]
     
     return cell
     }
     */
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
