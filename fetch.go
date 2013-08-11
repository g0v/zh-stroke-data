package main
import "fmt"
import "net/http"
import "log"
import "io/ioutil"
import "os"
import "path"
import "strings"
import "runtime"
import "time"

const baseDir = "data"
const xmlBaseUrl = "http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do?big5="
const bpmfXmlBaseUrl = "http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do?bpm="
const imageBaseUrl = "http://stroke-order.learningweb.moe.edu.tw/showWordImage.do?big5="


func fetchUrl(url string) (*[]byte, error) {
	res, err := http.Get(url)
	defer res.Body.Close()
	if err != nil {
		return nil, err
	}
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}
	return &body, nil
}

func fetchStrokeXml(code int) {
	var url,filename string
	hex := fmt.Sprintf("%x",code)

	fi, err := os.Stat(filename)

	if (0xA374 <= code && code <= 0xA37E) {
		url = bpmfXmlBaseUrl + fmt.Sprintf("%d", code - 0xA374 + 1)
	} else if (0xA3A1 <= code && code <= 0xA3BA) {
		url = bpmfXmlBaseUrl + fmt.Sprintf("%d", code - 0xA3A1 + 12)
	} else {
		url = xmlBaseUrl + hex
	}

	filename = path.Join( baseDir, hex + ".xml" )

	if fi != nil {
		fmt.Print("-")
		return
	}

	xmlContentP, err := fetchUrl(url)
	if err != nil {
		log.Println(err)
		return
	}

	xmlContent := *xmlContentP

	if ! strings.HasPrefix(string(xmlContent), "<?xml") {
		fmt.Print("x")
		// log.Printf("ERROR: %s returns non-XML response",url)
		return
	}

	// filename string, data []byte, perm os.FileMode
	fmt.Print(".")
	ioutil.WriteFile(filename, xmlContent, 0666)
	time.Sleep(500 * time.Millisecond)
}

func main() {
	in := make(chan int, 10)
	done := make(chan bool)

	worker := func(in chan int, done chan bool) {
		for {
			c := <-in
			if c == 0 {
				break
			}
			fetchStrokeXml(c)
		}
		done <- true
	}

	for i := 0 ; i < runtime.NumCPU() ; i++ {
		go worker(in, done)
	}

	// 0xA374-0XA37E
	// 0xA3A1-0xA3BA for Bopomofo
	// 0xA440-0xC67E
	// 0xC940-0xF9D5
	os.Mkdir(baseDir, 0777)

	for code := 0xa374 ; code <= 0xa37e ; code++ {
		in <- code
	}

	for code := 0xa3a1 ; code <= 0xa3ba ; code++ {
		in <- code
	}

	for code := 0xa440 ; code <= 0xc67e ; code++ {
		in <- code
	}

	for i := 0 ; i < runtime.NumCPU() ; i++ {
		in <- 0
		<-done
		fmt.Printf("goroutine %d finished\n", i)
	}
}
