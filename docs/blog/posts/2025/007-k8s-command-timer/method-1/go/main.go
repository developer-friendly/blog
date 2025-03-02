package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

var (
	PUSHGATEWAY_URL = os.Getenv("PUSHGATEWAY_URL")
	JOB_NAME        = os.Getenv("JOB_NAME")
	INSTANCE_NAME   = os.Getenv("INSTANCE_NAME")
)

// This is the main one-off task we want to execute.
//
// The other helper functions in this file are just measuring the duration
// of this task.
func theMainJob() {
	time.Sleep(1 * time.Second)
}

func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		fmt.Println("Error getting hostname:", err)
		return "unknown"
	}
	return hostname
}

func initDefaults() {
	if PUSHGATEWAY_URL == "" {
		PUSHGATEWAY_URL = "http://localhost:9091"
	}

	if JOB_NAME == "" {
		JOB_NAME = "my_job"
	}

	if INSTANCE_NAME == "" {
		INSTANCE_NAME = getHostname()
	}
}

func main() {
	initDefaults()

	fmt.Println("Starting the job...")

	start := time.Now()

	theMainJob()

	duration := time.Since(start).Seconds()

	fmt.Println("Job execution finished, push the metrics...")

	pushURL := fmt.Sprintf("%s/metrics/job/%s/instance/%s/lang/go", PUSHGATEWAY_URL, JOB_NAME, INSTANCE_NAME)

	fmt.Println("Pushing to Pushgateway:", pushURL)

	req, err := http.NewRequest("POST", pushURL, nil)
	if err != nil {
		fmt.Println("Error creating request:", err)
		return
	}

	payload := fmt.Sprintf(`
# TYPE job_duration_seconds gauge
# HELP job_duration_seconds Duration of the job in seconds
job_duration_seconds %s
`, fmt.Sprintf("%f", duration))

	httpPayload := strings.NewReader(payload)

	client := &http.Client{}
	req.Body = io.NopCloser(httpPayload)
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error pushing to Pushgateway:", err)
		return
	}
	defer resp.Body.Close()

	fmt.Println("Execution time pushed successfully:", duration)
}
