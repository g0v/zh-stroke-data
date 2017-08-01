常用國字標準字體筆劃 XML 資料檔
===============================

## 抓資料 / Fetch resources

```go
go run fetch.go
```

---

`fetch.go` 從 `http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do` 抓筆順資料。

使用參數 `big5=<case-insensitive Big5 code in hex>` 可以取得筆順資料。

加上參數 `bpm=<index>` 可以取得從 1 開始索引的筆順，注意在 Big5 編碼中，注音符號是不連續的，但此處的索引是連續的：

`fetch.go` gets bopomofo strokes and chinese character strokes from `http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do`.

Character strokes are fetched by parameter `big5=<case-insensitive Big5 code in hex>`.

Bopomofo strokes are indexed by intergers with parameter `bpm=<index>`, but they are not continuous in Big5:

```
bopomofo,big5,index
ㄅ,0xA374,1
ㄆ,0xA375,2
ㄇ,0xA376,3
ㄈ,0xA377,4
ㄉ,0xA378,5
ㄊ,0xA379,6
ㄋ,0xA37A,7
ㄌ,0xA37B,8
ㄍ,0xA37C,9
ㄎ,0xA37D,10
ㄏ,0xA37E,11
ㄐ,0xA3A1,12
ㄑ,0xA3A2,13
ㄒ,0xA3A3,14
ㄓ,0xA3A4,15
ㄔ,0xA3A5,16
ㄕ,0xA3A6,17
ㄖ,0xA3A7,18
ㄗ,0xA3A8,19
ㄘ,0xA3A9,20
ㄙ,0xA3AA,21
ㄚ,0xA3AB,22
ㄛ,0xA3AC,23
ㄜ,0xA3AD,24
ㄝ,0xA3AE,25
ㄞ,0xA3AF,26
ㄟ,0xA3B0,27
ㄠ,0xA3B1,28
ㄡ,0xA3B2,29
ㄢ,0xA3B3,30
ㄣ,0xA3B4,31
ㄤ,0xA3B5,32
ㄥ,0xA3B6,33
ㄦ,0xA3B7,34
ㄧ,0xA3B8,35
ㄨ,0xA3B9,36
ㄩ,0xA3BA,37
```

調號筆順由 2016 年的[注音符號手冊][bopomofo-handbook]提供。

加上參數 `useAlt=1` 時，可以拿到注音符號的另外一種寫法。現在只有`ㄓ`（索引 15）和`ㄖ`（索引 18）有不同寫法。

Tonal marks' strokes are created by [caasi/bopomofo-handbook][bopomofo-handbook].

With parameter `useAlt=1`, you can get alternative strokes. Only `ㄓ`(index 15) and `ㄖ`(index 18) have alternative strokes for now. And they are not fetched by `fetch.go`.

[bopomofo-handbook]: https://github.com/caasi/bopomofo-handbook

## 將檔案以 Unicode code point 重新命名 / Rename files from Big5 to Unicode code point

```
./link2utf8.pl
```

## 產生 demo 用的 script / Create the demo script

```compile
npm install
npm run compile
```

---

我們用 [grunt][grunt] 來轉譯 CoffeeScript 。 `grunt` 在下 `npm install` 指令時會自動裝好。細節請看 `Gruntfile.js` 。

This project uses [grunt][grunt] to transpile CoffeeScripts to JavaScripts and bundle them. `grunt` will be installed by `npm install` automatically. Check `Gruntfile.js` to get more information.

[grunt]: https://gruntjs.com

## 將 xml 筆劃資料轉換成 json 格式 / Convert data from XML to JSON

```stroke2json.sh
./stroke2json.sh
```

---

`stroke2json.sh` 用 `stroke2json.js` 將筆順資料從 XML 轉成 JSON 。 `stroke2json.js` 的原始碼在 `coffee/stroke2json.coffee` 。

`stroke2json.sh` calls `stroke2json.js` to transform stroke data from XML to JSON which is built from `coffee/stroke2json.coffee`.

## 以 missing 中的資料組合出其他字的 json 筆劃資料

```compose.sh
./compose.sh
```

`compose.sh` 用 `compose.js` 來組合筆順資料，原始碼在 `coffee/compose.coffee` 。

描述新筆順的資料在 `missing/` 資料夾下，從數個字中挑選出個別筆畫，變形後組合出新字。

`compose.sh` calls `compose.js` to compose new storkes which is built from `coffee/compose.coffee`.

Composing instructions are under `missing/`. It tells the script how to pick and transform strokes from characters.

## 資料來源 / Copyright

常用國字標準字體筆順學習網 <http://stroke-order.learningweb.moe.edu.tw>

「常用國字標準字體筆順學習網」著作權係中華民國教育部所有。其目的為提供本部標準楷體字之筆順教學利用，不得用於商業用途。

「筆劃 XML 資料檔」不屬於教育部上述授權範圍，而是自網頁版自行取得，為非營利之教育目的，依著作權法第50條，
「以中央或地方機關或公法人之名義公開發表之著作，在合理 範圍內，得重製、公開播送或公開傳輸。」

除前述資料檔之外，本目錄下的所有其他檔案，由作者林佑安在法律許可的範圍內，
拋棄該著作依著作權法所享有之權利，包括所有相關 與鄰接的法律權利，並宣告將該著作貢獻至公眾領域。

