package app

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/google/uuid"
)

func TestMezzotoneModelExportSavesRenderedContentToHome(t *testing.T) {
	tmpHome := t.TempDir()
	t.Setenv("HOME", tmpHome)
	fixedUUID := uuid.MustParse("41c92b29-4eb7-4f33-bf3c-8a3d29efe330")
	previousNewUUID := newUUID
	newUUID = func() uuid.UUID { return fixedUUID }
	t.Cleanup(func() { newUUID = previousNewUUID })

	m := NewMezzotoneModel()
	m.currentActiveMenu = renderViewText
	m.renderContent = "rendered-output"
	m.style.leftColumnWidth = 120

	_, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'e'}})

	exportPath := filepath.Join(tmpHome, "Mezzotone_"+fixedUUID.String()+".txt")
	t.Cleanup(func() {
		if err := os.Remove(exportPath); err != nil && !os.IsNotExist(err) {
			t.Fatalf("failed to remove exported file %q: %v", exportPath, err)
		}
	})
	got, err := os.ReadFile(exportPath)
	if err != nil {
		t.Fatalf("expected exported file at %q, got read error: %v", exportPath, err)
	}
	if string(got) != m.renderContent {
		t.Fatalf("expected exported file content %q, got %q", m.renderContent, string(got))
	}
}

func TestMezzotoneModelCopyToClipboardWhenUnavailableShowsError(t *testing.T) {
	previousClipboardOK := clipboardOK
	t.Cleanup(func() { clipboardOK = previousClipboardOK })

	m := NewMezzotoneModel()
	m.currentActiveMenu = renderViewText
	m.style.leftColumnWidth = 120
	clipboardOK = false

	_, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'c'}})

	if !strings.Contains(m.messageViewPort.View(), "Clipboard not available (init failed)") {
		t.Fatalf("expected clipboard unavailable message, got %q", m.messageViewPort.View())
	}
}
