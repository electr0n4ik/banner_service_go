package main

import (
	"log"
	"net/http"

	deliveryhttp "banner_service_go/internal/delivery"
)

func main() {
	// Регистрация обработчиков HTTP-запросов
	http.HandleFunc("/", deliveryhttp.HelloHandler)

	// Запуск сервера
	port := ":8080"
	log.Printf("Server started on port %s", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
