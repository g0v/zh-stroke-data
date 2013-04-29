package main
import "fmt"
import "net/http"
import "log"
import "io/ioutil"
import "os"
import "path"
import "strings"
import "runtime"

const baseDir = "data"
const baseUrl = "http://stroke-order.learningweb.moe.edu.tw/provideStrokeInfo.do?big5="

func fetchStroke(code int) {
	hex := fmt.Sprintf("%x",code)
	url := baseUrl + hex
	filename := path.Join( baseDir, hex + ".xml" )

	fi, err := os.Stat(filename)
	if fi != nil {
		fmt.Print("-")
		return
	}

	res, err := http.Get(url)
	if err != nil {
		log.Println(err)
	}
	xmlContent, err := ioutil.ReadAll(res.Body)

	defer func() {
		res.Body.Close()
	}()

	if err != nil {
		log.Println(err)
		return
	}

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
			fetchStroke(c)
		}
		done <- true
	}

	for i := 0 ; i < runtime.NumCPU() ; i++ {
		go worker(in, done)
	}

	// 0xA440-0xC67E
	// 0xC940-0xF9D5
	os.Mkdir(baseDir, 0777)

	for code := 0xa440 ; code < 0xc67e ; code++ {
		in <- code
	}

	for i := 0 ; i < runtime.NumCPU() ; i++ {
		in <- 0
		<-done
		fmt.Printf("goroutine %d finished", i)
	}
}
