package main

import (
	"fmt"
	"log"
)

func main() {
	fmt.Println("Banner Service Go")

	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	// Здесь будет основная логика приложения
	return nil
}
