package deliveryhttp

import (
	"log"
	"net/http"
)

func HelloHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	if _, err := w.Write([]byte("Hello World!")); err != nil {
		log.Fatalf("Ошибка записи в ответ: %s", err)
	}
}
