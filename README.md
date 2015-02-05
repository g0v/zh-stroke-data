常用國字標準字體筆劃 XML 資料檔
===============================

## 抓資料 / Install resources

```go
go run fetch.go
```

## 產生 demo 用的 script / Create the demo script

```compile
npm install -g grunt-cli
npm install --dev
grunt
```

## 將 xml 筆劃資料轉換成 json 格式 / Convert data from xml to json

```stroke2json
node ./stroke2json.js <filename>
```

## 產生 json 筆劃資料 / Create stroke order resources

```stroke2json.sh
./stroke2json.sh
```

## 以 missing 中的資料組合出其他字的 json 筆劃資料

```compose.sh
./compose.sh
```

## 資料來源 / Copyright

常用國字標準字體筆順學習網 <http://stroke-order.learningweb.moe.edu.tw>

「常用國字標準字體筆順學習網」著作權係中華民國教育部所有。其目的為提供本部標準楷體字之筆順教學利用，不得用於商業用途。

「筆劃 XML 資料檔」不屬於教育部上述授權範圍，而是自網頁版自行取得，為非營利之教育目的，依著作權法第50條，
「以中央或地方機關或公法人之名義公開發表之著作，在合理 範圍內，得重製、公開播送或公開傳輸。」

除前述資料檔之外，本目錄下的所有其他檔案，由作者林佑安在法律許可的範圍內，
拋棄該著作依著作權法所享有之權利，包括所有相關 與鄰接的法律權利，並宣告將該著作貢獻至公眾領域。


