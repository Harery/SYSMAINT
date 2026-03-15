// Package state provides state management with SQLite
package state

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

type State struct {
	db   *sql.DB
	path string
}

type Operation struct {
	ID          int64
	Timestamp   time.Time
	Type        string
	Description string
	Status      string
	Output      string
	Duration    int64
}

type HealthMetric struct {
	ID          int64
	Timestamp   time.Time
	MetricType  string
	Name        string
	Value       float64
	Unit        string
}

func New(dbPath string) (*State, error) {
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create state directory: %w", err)
	}

	db, err := sql.Open("sqlite3", dbPath+"?_journal_mode=WAL")
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	s := &State{db: db, path: dbPath}
	if err := s.migrate(); err != nil {
		return nil, fmt.Errorf("failed to migrate database: %w", err)
	}

	return s, nil
}

func (s *State) migrate() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS operations (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
			type TEXT NOT NULL,
			description TEXT,
			status TEXT NOT NULL,
			output TEXT,
			duration_ms INTEGER
		)`,
		`CREATE TABLE IF NOT EXISTS health_metrics (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
			metric_type TEXT NOT NULL,
			name TEXT NOT NULL,
			value REAL NOT NULL,
			unit TEXT
		)`,
		`CREATE TABLE IF NOT EXISTS snapshots (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
			name TEXT NOT NULL,
			description TEXT,
			data TEXT
		)`,
		`CREATE INDEX IF NOT EXISTS idx_operations_timestamp ON operations(timestamp)`,
		`CREATE INDEX IF NOT EXISTS idx_health_metrics_timestamp ON health_metrics(timestamp)`,
	}

	for _, q := range queries {
		if _, err := s.db.Exec(q); err != nil {
			return err
		}
	}
	return nil
}

func (s *State) RecordOperation(opType, description, status, output string, duration time.Duration) (int64, error) {
	result, err := s.db.Exec(
		`INSERT INTO operations (type, description, status, output, duration_ms) VALUES (?, ?, ?, ?, ?)`,
		opType, description, status, output, duration.Milliseconds(),
	)
	if err != nil {
		return 0, err
	}
	return result.LastInsertId()
}

func (s *State) GetOperations(limit int) ([]Operation, error) {
	rows, err := s.db.Query(
		`SELECT id, timestamp, type, description, status, output, duration_ms 
		 FROM operations ORDER BY timestamp DESC LIMIT ?`,
		limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ops []Operation
	for rows.Next() {
		var op Operation
		if err := rows.Scan(&op.ID, &op.Timestamp, &op.Type, &op.Description, &op.Status, &op.Output, &op.Duration); err != nil {
			return nil, err
		}
		ops = append(ops, op)
	}
	return ops, nil
}

func (s *State) RecordMetric(metricType, name, unit string, value float64) error {
	_, err := s.db.Exec(
		`INSERT INTO health_metrics (metric_type, name, value, unit) VALUES (?, ?, ?, ?)`,
		metricType, name, value, unit,
	)
	return err
}

func (s *State) GetMetrics(metricType string, since time.Time, limit int) ([]HealthMetric, error) {
	rows, err := s.db.Query(
		`SELECT id, timestamp, metric_type, name, value, unit 
		 FROM health_metrics 
		 WHERE metric_type = ? AND timestamp > ? 
		 ORDER BY timestamp DESC LIMIT ?`,
		metricType, since, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var metrics []HealthMetric
	for rows.Next() {
		var m HealthMetric
		if err := rows.Scan(&m.ID, &m.Timestamp, &m.MetricType, &m.Name, &m.Value, &m.Unit); err != nil {
			return nil, err
		}
		metrics = append(metrics, m)
	}
	return metrics, nil
}

func (s *State) CreateSnapshot(name, description, data string) (int64, error) {
	result, err := s.db.Exec(
		`INSERT INTO snapshots (name, description, data) VALUES (?, ?, ?)`,
		name, description, data,
	)
	if err != nil {
		return 0, err
	}
	return result.LastInsertId()
}

func (s *State) GetLatestSnapshot() (*Operation, error) {
	row := s.db.QueryRow(
		`SELECT id, timestamp, type, description, status, output, duration_ms 
		 FROM snapshots ORDER BY timestamp DESC LIMIT 1`,
	)
	var op Operation
	err := row.Scan(&op.ID, &op.Timestamp, &op.Type, &op.Description, &op.Status, &op.Output, &op.Duration)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &op, nil
}

func (s *State) Close() error {
	return s.db.Close()
}
