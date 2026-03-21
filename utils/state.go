package utils

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var stateFile = os.Getenv("HOME") + "/.switch_state"
var panelPidFile = os.Getenv("HOME") + "/.qswitch_panel_pid"

func ReadState() string {
	data, err := os.ReadFile(stateFile)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

func WriteState(f string) {
	os.WriteFile(stateFile, []byte(f), 0644)
}

func GetFlavourPath(flavour string) (string, bool) {

	if flavour == "dms" {
		_, err := exec.LookPath("dms")
		if err != nil {
			return "", false
		}
		return flavour, true
	}

	roots := []string{
		filepath.Join(os.Getenv("HOME"), ".config", "quickshell"),
		"/etc/xdg/quickshell",
		"/usr/share/quickshell",
		"/usr/local/share/quickshell",
	}

	for _, root := range roots {

		foundPath := ""

		filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
			if err != nil || foundPath != "" {
				return nil
			}

			if d.IsDir() && filepath.Base(path) == flavour {
				foundPath = path
				return filepath.SkipDir
			}

			return nil
		})

		if foundPath != "" {
			return foundPath, true
		}
	}

	return "", false
}

func IsFlavourInstalled(flavour string) bool {
	_, ok := GetFlavourPath(flavour)
	return ok
}

func CheckFirstRun() bool {
	if _, err := os.Stat(stateFile); err == nil {
		return false
	}
	return true
}