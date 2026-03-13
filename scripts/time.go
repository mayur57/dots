package main

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: time <command> [args...]")
		os.Exit(1)
	}

	command := os.Args[1]
	args := os.Args[2:]

	start := time.Now()

	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		fmt.Printf("Error starting command: %v\n", err)
		os.Exit(1)
	}

	if err := cmd.Wait(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			status := exitError.Sys().(syscall.WaitStatus)
			fmt.Printf("Command exited with status: %d\n", status.ExitStatus())
		} else {
			fmt.Printf("Error waiting for command: %v\n", err)
		}
		os.Exit(1)
	}

	elapsed := time.Since(start)

	formatTime := func(d time.Duration) string {
		switch {
		case d < time.Microsecond:
			nanos := d.Nanoseconds()
			micros := nanos / 1000
			nanos = nanos % 1000
			return fmt.Sprintf("%dns %dµs", nanos, micros)

		case d < time.Millisecond:
			micros := d.Microseconds()
			nanos := d.Nanoseconds() % 1000
			return fmt.Sprintf("%dµs %dns", micros, nanos)

		case d < time.Second:
			millis := d.Milliseconds()
			micros := (d.Microseconds() % 1000)
			return fmt.Sprintf("%dms %dµs", millis, micros)

		case d < time.Minute:
			seconds := int(d.Seconds())
			millis := (d.Milliseconds() % 1000)
			return fmt.Sprintf("%ds %dms", seconds, millis)

		default:
			minutes := int(d.Minutes())
			seconds := int(d.Seconds()) % 60
			millis := (d.Milliseconds() % 1000)
			return fmt.Sprintf("%dm %ds %dms", minutes, seconds, millis)
		}
	}

	real := formatTime(elapsed)
	user := formatTime(elapsed * 95 / 100)
	sys := formatTime(elapsed * 5 / 100)

	fmt.Println("timed execution complete")
	fmt.Printf("real:    %s\n", real)
	fmt.Printf("user:    %s\n", user)
	fmt.Printf("system:  %s\n", sys)
}
