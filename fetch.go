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

const DELAY = 1500
const BASEDIR = "data"
const XMLBASEURL = "http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do?big5="
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
	hex := fmt.Sprintf("%x",code)
	url := XMLBASEURL + hex
	filename := path.Join( BASEDIR, hex + ".xml" )

	fi, err := os.Stat(filename)
	if fi != nil {
		fmt.Print("-")
		return
	}

	time.Sleep(DELAY * time.Millisecond)
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

	// 0xA440-0xC67E
	// 0xC940-0xF9D5
	os.Mkdir(BASEDIR, 0777)

	for code := 0xa440 ; code < 0xc67e ; code++ {
		in <- code
	}

	for i := 0 ; i < runtime.NumCPU() ; i++ {
		in <- 0
		<-done
		fmt.Printf("goroutine %d finished\n", i)
	}
}
