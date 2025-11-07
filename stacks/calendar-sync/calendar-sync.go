// - delete events from primary calendar matching the magic string
// - iterate source calendar, creating events on primary with the magic string

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/option"
	"gopkg.in/yaml.v3"
)

type CalendarSyncConfigEntry struct {
	MagicString string `yaml:"magicString"`
	Name        string `yaml:"name"`
	TimeZone    string `yaml:"timeZone"`
	Summary     string `yaml:"summary"`
}

type CalendarSyncConfig struct {
	Entries []CalendarSyncConfigEntry `yaml:"entries"`
}

// Retrieve a token, saves the token, then returns the generated client.
func getClient(config *oauth2.Config) *http.Client {
	// The file token.json stores the user's access and refresh tokens, and is
	// created automatically when the authorization flow completes for the first
	// time.
	tokFile := filepath.Join(os.Getenv("DATA_DIR"), "token.json")
	tok, err := tokenFromFile(tokFile)
	if err != nil {
		tok = getTokenFromWeb(config)
		saveToken(tokFile, tok)
	}
	return config.Client(context.Background(), tok)
}

// Request a token from the web, then returns the retrieved token.
func getTokenFromWeb(config *oauth2.Config) *oauth2.Token {
	authURL := config.AuthCodeURL("state-token", oauth2.AccessTypeOffline)
	fmt.Printf("Go to the following link in your browser then type the "+
		"authorization code: \n%v\n", authURL)

	var authCode string
	if _, err := fmt.Scan(&authCode); err != nil {
		log.Fatalf("Unable to read authorization code: %v", err)
	}

	tok, err := config.Exchange(context.TODO(), authCode)
	if err != nil {
		log.Fatalf("Unable to retrieve token from web: %v", err)
	}
	return tok
}

// Retrieves a token from a local file.
func tokenFromFile(file string) (*oauth2.Token, error) {
	f, err := os.Open(file)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	tok := &oauth2.Token{}
	err = json.NewDecoder(f).Decode(tok)
	return tok, err
}

// Saves a token to a file path.
func saveToken(path string, token *oauth2.Token) {
	fmt.Printf("Saving credential file to: %s\n", path)
	f, err := os.OpenFile(path, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		log.Fatalf("Unable to cache oauth token: %v", err)
	}
	defer f.Close()
	json.NewEncoder(f).Encode(token)
}

func dateTimeDiff(a *calendar.EventDateTime, b *calendar.EventDateTime) time.Duration {
	parsedA := parseDateTime(a)
	parsedB := parseDateTime(b)

	return parsedB.Sub(parsedA)
}

func parseDateTime(a *calendar.EventDateTime) time.Time {
	var parsed time.Time

	if a.DateTime == "" {
		parsed, _ = time.Parse(time.DateOnly, a.Date)
	} else {
		parsed, _ = time.Parse(time.RFC3339, a.DateTime)
	}
	return parsed
}

func deleteEventsFromPrimary(entry CalendarSyncConfigEntry, srv *calendar.Service) {
	magic_string := entry.MagicString

	t := time.Now().Format(time.RFC3339)
	end_t := time.Now().AddDate(0, 0, 20).Format(time.RFC3339)
	events, err := srv.Events.List("primary").Q(magic_string).ShowDeleted(false).
		SingleEvents(true).TimeMin(t).TimeMax(end_t).OrderBy("startTime").MaxResults(2500).Do()
	if err != nil {
		log.Fatalf("Unable to retrieve next ten of the user's events: %v", err)
	}

	if len(events.Items) > 0 {
		for _, item := range events.Items {
			err := srv.Events.Delete("primary", item.Id).Do()
			if err != nil {
				log.Fatalf("Unable to delete event: %v", err)
			}
		}
	}
}

func createEventsFromSource(entry CalendarSyncConfigEntry, srv *calendar.Service) {
	calendar_name := entry.Name
	tz := entry.TimeZone
	magic_string := entry.MagicString
	summary := entry.Summary

	maxDuration, _ := time.ParseDuration("3h")

	t := time.Now().Format(time.RFC3339)
	end_t := time.Now().AddDate(0, 0, 20).Format(time.RFC3339)

	events, err := srv.Events.List(calendar_name).ShowDeleted(false).
		SingleEvents(true).TimeMin(t).TimeMax(end_t).OrderBy("startTime").MaxResults(2500).Do()

	if err != nil {
		log.Fatalf("Unable to retrieve next ten of the user's events: %v", err)
	}

	if len(events.Items) > 0 {
		for _, item := range events.Items {
			end_t, _ := time.Parse(time.RFC3339, item.End.DateTime)

			if end_t.Minute()%10 == 7 {
				log.Printf("Ignored event, skipping")
				continue
			}

			new_start := calendar.EventDateTime{DateTime: item.Start.DateTime, TimeZone: tz}
			new_end := calendar.EventDateTime{DateTime: item.End.DateTime, TimeZone: tz}

			if item.Start.DateTime == "" {
				new_start = calendar.EventDateTime{Date: item.Start.Date, TimeZone: tz}
				new_end = calendar.EventDateTime{Date: item.End.Date, TimeZone: tz}
			}

			eventDuration := dateTimeDiff(&new_start, &new_end)
			log.Printf("duration: %v, maxDuration: %v", eventDuration, maxDuration)

			if eventDuration > maxDuration {
				log.Printf("Longer than maxDuration, skipping")
				continue
			}

			reminders := calendar.EventReminders{UseDefault: false}

			new_item := calendar.Event{
				Start:       &new_start,
				End:         &new_end,
				Description: magic_string,
				Summary:     summary,
				Reminders:   &reminders,
			}

			_, err := srv.Events.Insert("primary", &new_item).Do()
			if err != nil {
				log.Fatalf("Unable to create event %v: %v", new_item, err)
			}
		}
	}
}

func main() {
	ctx := context.Background()
	log.Print("Loading config")
	f, err := os.ReadFile(filepath.Join(os.Getenv("DATA_DIR"), "config.yaml"))
	if err != nil {
		log.Fatal(err)
	}

	var calendarConfig CalendarSyncConfig
	if err := yaml.Unmarshal(f, &calendarConfig); err != nil {
		log.Fatal(err)
	}

	log.Print("Attempting to connect to Google Calendar.....\n")
	b, err := os.ReadFile(filepath.Join(os.Getenv("DATA_DIR"), "credentials.json"))
	if err != nil {
		log.Fatalf("Unable to read client secret file: %v", err)
	}

	// If modifying these scopes, delete your previously saved token.json.
	config, err := google.ConfigFromJSON(b, calendar.CalendarScope)
	if err != nil {
		log.Fatalf("Unable to parse client secret file to config: %v", err)
	}
	client := getClient(config)

	srv, err := calendar.NewService(ctx, option.WithHTTPClient(client))
	if err != nil {
		log.Fatalf("Unable to retrieve Calendar client: %v", err)
	}

	log.Print("Connected to Google Calendar!\n")

	for _, entry := range calendarConfig.Entries {
		log.Printf("Syncing events from %s", entry.Name)

		deleteEventsFromPrimary(entry, srv)
		createEventsFromSource(entry, srv)
	}
}
