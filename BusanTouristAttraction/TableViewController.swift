//
//  TableViewController.swift
//  DynamicBusan
//
//  Created by 정순우 on 2017. 12. 15..
//  Copyright © 2017년 정순우. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController,XMLParserDelegate {
    
    var item:[String:String] = [:]
    var items:[[String:String]] = []
    var key = ""
    var servieKey = "yDiLmalCzWpsaoeTpkwBgxGTwleQQIDv6Wnrne98wO5fQCserlsYGM7nfwJl%2FdYK3dUWTedo0Hphsi9GucgcKA%3D%3D"
    var listEndPoint = "http://apis.data.go.kr/6260000/BusanTourInfoService/getTouristAttrList"
    let detailEndPoint = "http://apis.data.go.kr/6260000/BusanTourInfoService/getTouristAttDetail"
    
    var totalCount = 0 //총 갯수를 저장하는 변수
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "부산 관광 명소"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("data.plist")
        
        //print(url)
        
        //시작할때마다 TotalCount를 받아옴
        getList(numOfRows: 0)
        
        if fileManager.fileExists(atPath: (url?.path)!) {
            //파일이 있으면 파일에서 읽어옴
            items = NSArray(contentsOf: url!) as! Array
            
            //파일에서 읽어본 갯수와 totalCount를 비교
            if (items.count != totalCount) {
                //파일에서 읽어본 갯수와 totalCount가 다르면(변화가 있으면) 다시 읽어와서 저장
                getList(numOfRows: totalCount)
                saveDetail(url: url!)
            }
        } else {
            //******* 파일이 없으면
            getList(numOfRows: totalCount)
            saveDetail(url: url!)
        }
        
        tableView.reloadData()
    }
    
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
                    print("parse failed in hetList")
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
        let tempItems = items  // tableView에서 재활용
        //print("items = \(items)")
        
        items = []
        //-----------------thread controll----------------------
        //-------DispatchQueue선언(멀티 thread)-------------------
        //qos 속성에 따라 우선순위 변경
        let equeue = DispatchQueue(label:"com.yangsoo.queue", qos:DispatchQoS.userInitiated)
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
                    self.tableView.reloadData()
                    let temp = self.items as NSArray  // NSArry는 화일로 저장하기 위함
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
            items.append(item)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "RE", for: indexPath)
        
        let dic = items[indexPath.row]
        cell.textLabel?.text = dic["dataTitle"]
        cell.detailTextLabel?.text = dic["addr"]
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
            
            if segue.identifier == "DetailView" {
            let singleMTVC = segue.destination as! DetailViewController
            let selectedIndex = tableView.indexPathForSelectedRow
            singleMTVC.sItem = items[(selectedIndex?.row)!]
            print(items[(selectedIndex?.row)!])
            
        }
    }
}

