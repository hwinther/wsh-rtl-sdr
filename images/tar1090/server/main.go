// tar1090-server serves tar1090's static web UI and readsb's JSON directory with the headers
// tar1090's own nginx.conf sets, as one static binary with no dependencies beyond the standard
// library (a candidate for the shared wshno/static-server).
//
//	/data/...  readsb's JSON directory ($DATA_DIR, default /run/readsb), always revalidated. readsb
//	           writes globe_*.json, *.binCraft and traces gzip-compressed without a .gz suffix, so
//	           those get Content-Encoding: gzip; aircraft.json and friends are gzipped on the fly.
//	/...       the tar1090 html directory ($HTML_DIR, default /usr/share/tar1090/html). Cache-busted
//	           js/css/images are cached for two weeks, index.html and the mounted config.js /
//	           upintheair.json are revalidated, and the gzip-compressed aircraft database
//	           (db-<version>/*.js) gets Content-Encoding: gzip.
//
// Directory listings are off. Listens on $LISTEN (default :8080).
package main

import (
	"compress/gzip"
	"io"
	"log"
	"net/http"
	"os"
	"path"
	"regexp"
	"strings"
	"time"
)

var (
	// readsb output that is already gzip-compressed (tar1090's nginx.conf: globe_*.json, *.binCraft,
	// traces/trace_recent_*, traces/trace_full_*).
	dataGzipped = regexp.MustCompile(`(\.binCraft$|/globe_[0-9]+\.json$|/trace_(recent|full)_)`)
	// The aircraft database: gzip-compressed .js files.
	htmlGzipped = regexp.MustCompile(`^/db-[^/]+/.*\.js$`)
	// Cache-busted or versioned static assets.
	htmlStatic = regexp.MustCompile(`\.(js|css|png|svg|ico|gif|jpg)$`)
	// Mounted per deployment or rewritten per build: always revalidate.
	htmlNoCache = map[string]bool{
		"/": true, "/index.html": true, "/config.js": true, "/upintheair.json": true, "/version.json": true,
	}
)

func env(name, fallback string) string {
	if v := os.Getenv(name); v != "" {
		return v
	}
	return fallback
}

// noDirs hides directories (no listings); http.FileServer still serves a directory's index.html.
type noDirs struct{ http.FileSystem }

func (fs noDirs) Open(name string) (http.File, error) {
	f, err := fs.FileSystem.Open(name)
	if err != nil {
		return nil, err
	}
	if st, err := f.Stat(); err == nil && st.IsDir() {
		if idx, err := fs.FileSystem.Open(path.Join(name, "index.html")); err == nil {
			idx.Close()
			return f, nil
		}
		f.Close()
		return nil, os.ErrNotExist
	}
	return f, nil
}

type gzipWriter struct {
	http.ResponseWriter
	gz io.Writer
}

func (w gzipWriter) Write(b []byte) (int, error) { return w.gz.Write(b) }

func dataHandler(dir string) http.Handler {
	files := http.FileServer(noDirs{http.Dir(dir)})
	return http.StripPrefix("/data", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("Cache-Control", "no-cache")
		switch {
		case dataGzipped.MatchString(r.URL.Path):
			h.Set("Content-Encoding", "gzip")
		case strings.HasSuffix(r.URL.Path, ".json") && strings.Contains(r.Header.Get("Accept-Encoding"), "gzip"):
			h.Set("Content-Encoding", "gzip")
			h.Add("Vary", "Accept-Encoding")
			gz, _ := gzip.NewWriterLevel(w, gzip.BestSpeed)
			defer gz.Close()
			// The compressed length differs from the file's, and ranges would address the wrong bytes.
			r.Header.Del("Range")
			w = gzipWriter{ResponseWriter: noLength{w}, gz: gz}
		}
		files.ServeHTTP(w, r)
	}))
}

// noLength drops the Content-Length http.FileServer sets from the uncompressed file size.
type noLength struct{ http.ResponseWriter }

func (w noLength) WriteHeader(code int) {
	w.Header().Del("Content-Length")
	w.ResponseWriter.WriteHeader(code)
}

func htmlHandler(dir string) http.Handler {
	files := http.FileServer(noDirs{http.Dir(dir)})
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		p := r.URL.Path
		switch {
		case htmlNoCache[p]:
			h.Set("Cache-Control", "no-cache")
		case htmlStatic.MatchString(p):
			h.Set("Cache-Control", "public, max-age=1209600")
		}
		if htmlGzipped.MatchString(p) {
			h.Set("Content-Encoding", "gzip")
		}
		files.ServeHTTP(w, r)
	})
}

func main() {
	mux := http.NewServeMux()
	mux.Handle("/data/", dataHandler(env("DATA_DIR", "/run/readsb")))
	mux.Handle("/", htmlHandler(env("HTML_DIR", "/usr/share/tar1090/html")))

	addr := env("LISTEN", ":8080")
	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	log.Printf("tar1090-server listening on %s", addr)
	log.Fatal(srv.ListenAndServe())
}
