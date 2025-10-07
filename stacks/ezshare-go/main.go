package main

import (
	"fmt"
	"log"
	"io"
	"net/http"
	"net/url"	
	"strings"
	"time"
	"path"
	"path/filepath"
	"os"

	"github.com/PuerkitoBio/goquery"
)

type downloadable struct {
	path string
	downloadKey string
	mtime time.Time
}

func (d *downloadable) url() string {
	return fmt.Sprintf("http://ezshare.card/download?file=%s", d.downloadKey)
}

func (d *downloadable) shouldDownload() bool {
	fileInfo, err := os.Stat(d.fullPath())
	if err != nil {
		return true
	}

	return fileInfo.ModTime().Before(d.mtime)
}

func (d *downloadable) fullPath() string {
	return path.Join(os.Getenv("DATA_DIR"), d.path)	
}

func (d *downloadable) tempPath() string {
	return d.fullPath() + ".temp"
}

func processDownloadable(d *downloadable) {
	if !d.shouldDownload() {
		return
	}

	fmt.Printf("%s %s\n", d.url(), d.fullPath())

	resp, err := http.Get(d.url())
	if err != nil {
		log.Printf("%v", err)
		return
	}
	defer resp.Body.Close()

	os.MkdirAll(filepath.Dir(d.fullPath()), 0755)

	bytes, _ := io.ReadAll(resp.Body)
	err = os.WriteFile(d.tempPath(), bytes, 0644)
	if err != nil {
		log.Fatal(err)
	}

	err = os.Rename(d.tempPath(), d.fullPath())
	if err != nil {
		log.Fatal(err)
	}
}

func processListing(localPath string, href string) {
	listingUrl := fmt.Sprintf("http://ezshare.card/%s", href)

	resp, _ := http.Get(listingUrl)
	defer resp.Body.Close()

	doc, err := goquery.NewDocumentFromReader(resp.Body)	
	if err != nil {
    log.Fatal(err)
  }

	doc.Find("pre").Each(func(i int, s *goquery.Selection) {
		lines := strings.Split(s.Text(), "\n")

		s.Find("a").Each(func(j int, a *goquery.Selection) {
			line := lines[j]

			line = strings.Replace(line, "- ", "-0", -1)
			line = strings.Replace(line, ": ", ":0", -1)

			lineParts := strings.Fields(line)
			if lineParts[3] == "." || lineParts[3] == ".." {
				return
			}

			href, _ := a.Attr("href")

			if lineParts[2] == "<DIR>" {
				processListing(path.Join(localPath, lineParts[3]), href)
			} else {
				location, _ := time.LoadLocation("America/Detroit")
				cardMtime, _ := time.ParseInLocation("2006-01-02T15:04:05", fmt.Sprintf("%sT%s", lineParts[0], lineParts[1]), location)

				u, _ := url.Parse(href)
				v := u.Query()

				downloadKey := v["file"][0]

				d := &downloadable{
					path: path.Join(localPath, lineParts[3]),
					downloadKey: downloadKey,
					mtime: cardMtime,
				}

				processDownloadable(d)
			}
		})
	})	
}

func main() {
	log.Printf("Startup!")
	for range time.Tick(time.Minute * 60) {
		go func() {
			log.Printf("Scanning...")
			processListing(".", "dir?dir=A:")
		}()
	}
}
