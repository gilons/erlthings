package main

import (
	"crypto/tls"
	"fmt"
	"net/http"
)

const (
	URL = "http://localhost:8082/api/users"
)

func main() {
	_, err := http.Get(URL)
	if err != nil {
		fmt.Println(err.Error())
	}
	customTransport := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	customClient := &http.Client{
		Transport: customTransport,
	}
	response, err := customClient.Get(URL)
	if err != nil {
		fmt.Println(err.Error())
	} else {
		fmt.Println(response)
	}
}
