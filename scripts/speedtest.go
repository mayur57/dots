package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

const (
	// Upload: Use httpbin.org for upload testing (reliable POST endpoint)
	uploadURL      = "https://httpbin.org/post"
	uploadSize     = 10 * 1024 * 1024
	connectTimeout = 5 * time.Second
	testTimeout    = 30 * time.Second
)

const (
	colorRed    = "\033[31m"
	colorYellow = "\033[33m"
	colorGreen  = "\033[32m"
	colorReset  = "\033[0m"
	clearLine   = "\033[2K\r" // Clear entire line and return to start
)

var (
	// Using alternative endpoints since Cloudflare changed their API
	// Download: Use reliable CDN endpoints for testing (with fallback)
	downloadURLs = []string{
		"https://proof.ovh.net/files/10Mb.dat",
		"https://proof.ovh.net/files/1Mb.dat",
		"https://speedtest.tele2.net/10MB.zip",
	}
)

func getSpeedColor(bps float64) string {
	mbps := bps / 1_000_000
	switch {
	case mbps >= 25:
		return colorGreen
	case mbps >= 2:
		return colorYellow
	default:
		return colorRed
	}
}

func formatSpeed(bps float64) string {
	color := getSpeedColor(bps)
	var speed string

	switch {
	case bps >= 1_000_000_000:
		speed = fmt.Sprintf("%.2f Gbps", bps/1_000_000_000)
	case bps >= 1_000_000:
		speed = fmt.Sprintf("%.2f Mbps", bps/1_000_000)
	case bps >= 1_000:
		speed = fmt.Sprintf("%.2f Kbps", bps/1_000)
	default:
		speed = fmt.Sprintf("%.2f bps", bps)
	}

	return color + speed + colorReset
}

func checkInternetConnection() bool {
	conn, err := net.DialTimeout("tcp", "8.8.8.8:53", connectTimeout)
	if err != nil {
		return false
	}
	if conn != nil {
		conn.Close()
		return true
	}
	return false
}

func getNetworkType() string {
	// Check WiFi network name for hotspot indicators
	cmd := exec.Command("networksetup", "-getairportnetwork", "en0")
	output, err := cmd.Output()
	if err == nil {
		outputStr := strings.TrimSpace(string(output))
		if strings.HasPrefix(outputStr, "Current Wi-Fi Network:") {
			// Extract network name
			networkName := strings.TrimPrefix(outputStr, "Current Wi-Fi Network: ")
			networkName = strings.TrimSpace(networkName)
			networkNameLower := strings.ToLower(networkName)

			// Check for hotspot indicators in network name
			hotspotKeywords := []string{"iphone", "ipad", "android", "personal hotspot", "hotspot", "iphone de", "ipad de"}
			for _, keyword := range hotspotKeywords {
				if strings.Contains(networkNameLower, keyword) {
					return "Carrier Hotspot"
				}
			}
			return "WiFi"
		}
	}

	// Check for bridge interfaces (common indicator of personal hotspot)
	cmd = exec.Command("ifconfig")
	output, err = cmd.Output()
	if err == nil {
		outputStr := string(output)
		// Check for bridge interfaces which are often used for hotspots
		if strings.Contains(outputStr, "bridge") {
			// Check if it's a WiFi bridge (hotspot) vs other bridge
			if strings.Contains(outputStr, "en0") || strings.Contains(outputStr, "en1") {
				return "Carrier Hotspot"
			}
		}
	}

	// Check system_profiler for more detailed network info
	cmd = exec.Command("system_profiler", "SPNetworkDataType")
	output, err = cmd.Output()
	if err == nil {
		outputStr := string(output)
		if strings.Contains(strings.ToLower(outputStr), "personal hotspot") || strings.Contains(strings.ToLower(outputStr), "iphone") || strings.Contains(strings.ToLower(outputStr), "ipad") {
			return "Hotspot"
		}
		if strings.Contains(outputStr, "Wi-Fi") || strings.Contains(outputStr, "AirPort") {
			return "WiFi"
		}
	}

	// Default fallback - assume WiFi if we can't determine
	return "WiFi"
}

func printUsage() {
	fmt.Fprintf(os.Stderr, `Usage: %s [OPTIONS]

Test your internet connection speed using reliable speed test endpoints.

Options:
  -h, -help    Show this help message and exit

Examples:
  %s              Run speed test (download and upload)
  %s -h          Show usage information

Output:
  The script displays download (↓) and upload (↑) speeds in color:
  - Green:  ≥ 25 Mbps
  - Yellow: ≥ 2 Mbps
  - Red:    < 2 Mbps

Note: This script requires an active internet connection.
  Download test uses OVH's speed test file (100MB).
  Upload test uses httpbin.org POST endpoint (10MB).
`, os.Args[0], os.Args[0], os.Args[0])
}

func main() {
	help := flag.Bool("h", false, "Show usage information")
	helpLong := flag.Bool("help", false, "Show usage information")
	flag.Usage = printUsage
	flag.Parse()

	if *help || *helpLong {
		printUsage()
		os.Exit(0)
	}

	fmt.Print("Fetching network details...")

	if !checkInternetConnection() {
		fmt.Printf("%s%sNot connected to internet%s\n", clearLine, colorRed, colorReset)
		os.Exit(1)
	}

	networkType := getNetworkType()
	fmt.Printf("%sConnected to %s\n", clearLine, networkType)

	fmt.Print("↓ ")
	downloadSpeed, err := testDownload()
	if err != nil {
		fmt.Printf("\n%sError: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	fmt.Print("\t↑ ")
	_, err = testUpload(downloadSpeed)
	if err != nil {
		fmt.Printf("\n%sError: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}
	fmt.Println() // New line after final output
}

func testDownload() (float64, error) {
	client := &http.Client{
		Timeout: testTimeout,
	}

	var resp *http.Response
	var err error

	// Try each download URL until one works
	for _, url := range downloadURLs {
		resp, err = client.Get(url)
		if err == nil && resp.StatusCode == http.StatusOK {
			break
		}
		if resp != nil {
			resp.Body.Close()
		}
	}

	if err != nil {
		return 0, fmt.Errorf("download request failed: %w", err)
	}
	if resp == nil || resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("download failed: all endpoints returned errors")
	}
	defer resp.Body.Close()

	// Stream download and show real-time speed
	start := time.Now()
	totalBytes := int64(0)
	buffer := make([]byte, 32*1024) // 32KB buffer
	lastUpdate := time.Now()
	updateInterval := 200 * time.Millisecond // Update every 200ms

	for {
		n, err := resp.Body.Read(buffer)
		if n > 0 {
			totalBytes += int64(n)
			elapsed := time.Since(start).Seconds()

			// Update display periodically
			if time.Since(lastUpdate) >= updateInterval {
				if elapsed > 0 {
					currentSpeed := float64(totalBytes) * 8 / elapsed
					fmt.Printf("%s↓ %s", clearLine, formatSpeed(currentSpeed))
					lastUpdate = time.Now()
				}
			}
		}
		if err == io.EOF {
			break
		}
		if err != nil {
			return 0, fmt.Errorf("failed to read download response: %w", err)
		}
	}

	duration := time.Since(start).Seconds()
	if duration <= 0 {
		return 0, fmt.Errorf("invalid duration: %f seconds", duration)
	}

	// Display final speed
	bits := float64(totalBytes) * 8
	finalSpeed := bits / duration
	fmt.Printf("%s↓ %s", clearLine, formatSpeed(finalSpeed))
	return finalSpeed, nil
}

func testUpload(downloadSpeed float64) (float64, error) {
	data := bytes.Repeat([]byte("0"), uploadSize)

	// Create a custom reader that tracks bytes written
	reader := &progressReader{
		data:          bytes.NewReader(data),
		size:          int64(len(data)),
		downloadSpeed: downloadSpeed,
		onRead: func(bytesRead int64, elapsed time.Duration, dlSpeed float64) {
			if elapsed > 0 {
				currentSpeed := float64(bytesRead) * 8 / elapsed.Seconds()
				// Clear line and print both speeds
				fmt.Printf("%s↓ %s\t↑ %s", clearLine, formatSpeed(dlSpeed), formatSpeed(currentSpeed))
			}
		},
	}

	req, err := http.NewRequest("POST", uploadURL, reader)
	if err != nil {
		return 0, fmt.Errorf("failed to create upload request: %w", err)
	}

	req.ContentLength = int64(len(data))
	req.Header.Set("Content-Type", "application/octet-stream")

	client := &http.Client{
		Timeout: testTimeout,
	}

	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return 0, fmt.Errorf("upload request failed: %w", err)
	}
	defer resp.Body.Close()

	// Read the response body to ensure upload is complete
	_, err = io.Copy(io.Discard, resp.Body)
	if err != nil {
		return 0, fmt.Errorf("failed to read upload response: %w", err)
	}

	// httpbin.org returns 200 OK for POST requests
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("upload failed with status: %d", resp.StatusCode)
	}

	duration := time.Since(start).Seconds()
	if duration <= 0 {
		return 0, fmt.Errorf("invalid duration: %f seconds", duration)
	}

	// Display final speed
	bits := float64(len(data)) * 8
	finalSpeed := bits / duration
	fmt.Printf("%s↓ %s\t↑ %s", clearLine, formatSpeed(downloadSpeed), formatSpeed(finalSpeed))
	return finalSpeed, nil
}

// progressReader wraps an io.Reader to track progress
type progressReader struct {
	data          *bytes.Reader
	size          int64
	read          int64
	start         time.Time
	downloadSpeed float64
	onRead        func(int64, time.Duration, float64)
	lastUpdate    time.Time
}

func (pr *progressReader) Read(p []byte) (int, error) {
	if pr.start.IsZero() {
		pr.start = time.Now()
		pr.lastUpdate = time.Now()
	}

	n, err := pr.data.Read(p)
	pr.read += int64(n)

	// Update display periodically (every 200ms)
	if time.Since(pr.lastUpdate) >= 200*time.Millisecond {
		elapsed := time.Since(pr.start)
		if pr.onRead != nil {
			pr.onRead(pr.read, elapsed, pr.downloadSpeed)
		}
		pr.lastUpdate = time.Now()
	}

	return n, err
}
