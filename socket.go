package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"sync"
	"time"
)

type Event struct {
	EventID          string        `json:"id"`
	EventCreator     string        `json:"creator_phone"`
	AboutEvent       About         `json:"about"`
	EventPeriod      string        `json:"period"`
	EventPlace       string        `json:"location"`
	EventParticipant []Participant `json:"participant"`
}

type Participant struct {
	Phone  string `json:"phone"`
	Master bool   `json:"master"`
}

type About struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

var wg sync.WaitGroup

func main() {

	//for i := 0; i < 10000; i++ {
	//	go func(i int) {
	//wg.Add(1)
	//defer wg.Done()
	newEvent := initiateSampleEvent()
	jsonString, err := json.Marshal(newEvent)
	if err != nil {
		log.Println(err.Error())
	}
	startTime := time.Now()
	conn, err := net.Dial("tcp", "localhost:4500")
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(conn /*, i*/)
	conn.Write([]byte(jsonString))
	buffer := make([]byte, 10024)
	conn.Read(buffer)
	conn.Close()
	responseTime := (time.Now()).Sub(startTime)
	fmt.Println("Response Time = ", responseTime)
	fmt.Println(string(buffer) /*, i*/)
	//	}(2)
	//time.Sleep(100000)
	//}
	//wg.Wait()

}

func initiateSampleEvent() Event {
	about := About{
		Title: "Best Eaters In The World",
		Description: "Hello to every Participant \n" +
			"This event shall gather all the best eaters around the word\n" +
			"We Hope that all the world's countries shall be represented\n" +
			"thanks",
	}
	Participant1 := Participant{
		Phone:  "650594616",
		Master: true,
	}
	Participant2 := Participant{
		Phone:  "598683806",
		Master: true,
	}
	Participant3 := Participant{
		Phone:  "0025865325",
		Master: false,
	}
	Event := Event{
		EventID:      "e6e54sg69sg8321sdfgr987s6qzer98sdf",
		EventCreator: "650594616",
		EventPeriod:  "8-12-2018 14:50",
		EventPlace:   "Douala Yoga Palace",
		EventParticipant: []Participant{
			Participant1,
			Participant2,
			Participant3,
		},
		AboutEvent: about,
	}
	return Event
}
