package state

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestNew(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "pulse-state-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	dbPath := filepath.Join(tmpDir, "test.db")
	s, err := New(dbPath)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	defer s.Close()

	if _, err := os.Stat(dbPath); os.IsNotExist(err) {
		t.Error("database file should be created")
	}
}

func TestRecordOperation(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "pulse-state-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	s, err := New(filepath.Join(tmpDir, "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer s.Close()

	id, err := s.RecordOperation("update", "Package update", "success", "Updated 5 packages", time.Second)
	if err != nil {
		t.Fatalf("RecordOperation() error = %v", err)
	}

	if id == 0 {
		t.Error("ID should not be 0")
	}
}

func TestGetOperations(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "pulse-state-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	s, err := New(filepath.Join(tmpDir, "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer s.Close()

	for i := 0; i < 5; i++ {
		_, err := s.RecordOperation("update", "Package update", "success", "", time.Second)
		if err != nil {
			t.Fatal(err)
		}
	}

	ops, err := s.GetOperations(3)
	if err != nil {
		t.Fatalf("GetOperations() error = %v", err)
	}

	if len(ops) != 3 {
		t.Errorf("GetOperations() returned %d operations, want 3", len(ops))
	}
}

func TestRecordMetric(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "pulse-state-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	s, err := New(filepath.Join(tmpDir, "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer s.Close()

	err = s.RecordMetric("disk", "free_space", "GB", 50.5)
	if err != nil {
		t.Fatalf("RecordMetric() error = %v", err)
	}
}

func TestGetMetrics(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "pulse-state-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	s, err := New(filepath.Join(tmpDir, "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer s.Close()

	for i := 0; i < 10; i++ {
		s.RecordMetric("disk", "free_space", "GB", float64(i)*10)
	}

	metrics, err := s.GetMetrics("disk", time.Now().Add(-time.Hour), 5)
	if err != nil {
		t.Fatalf("GetMetrics() error = %v", err)
	}

	if len(metrics) != 5 {
		t.Errorf("GetMetrics() returned %d metrics, want 5", len(metrics))
	}
}

func TestCreateSnapshot(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "pulse-state-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	s, err := New(filepath.Join(tmpDir, "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer s.Close()

	id, err := s.CreateSnapshot("pre-update", "Before package update", "{}")
	if err != nil {
		t.Fatalf("CreateSnapshot() error = %v", err)
	}

	if id == 0 {
		t.Error("ID should not be 0")
	}
}
