# Go Testing Examples

## Testing Setup

```go
// testing_setup.go
package testsetup

import (
	"testing"
	"time"
	"os"
)

// Test configuration
type TestConfig struct {
	DatabaseURL string
	RedisURL    string
	Timeout     time.Duration
}

// Global test configuration
var Config TestConfig

func TestMain(m *testing.M) {
	// Setup test environment
	setupTestEnvironment()

	// Run tests
	code := m.Run()

	// Cleanup
	cleanupTestEnvironment()

	os.Exit(code)
}

func setupTestEnvironment() {
	Config = TestConfig{
		DatabaseURL: "postgres://test:test@localhost:5432/testdb?sslmode=disable",
		RedisURL:    "redis://localhost:6379/1",
		Timeout:     30 * time.Second,
	}

	// Wait for services to be ready
	waitForServices()
}

func cleanupTestEnvironment() {
	// Cleanup resources
}

func waitForServices() {
	// Wait for database and redis to be ready
}
```

## Table-Driven Tests

```go
package user

import (
	"testing"
)

func TestUserService(t *testing.T) {
	tests := []struct {
		name    string
		input   User
		want    error
		wantErr bool
	}{
		{
			name:    "valid user creation",
			input:   User{Name: "John", Email: "john@example.com"},
			want:    nil,
			wantErr: false,
		},
		{
			name:    "empty email",
			input:   User{Name: "John", Email: ""},
			want:    ErrInvalidEmail,
			wantErr: true,
		},
		{
			name:    "empty name",
			input:   User{Name: "", Email: "john@example.com"},
			want:    ErrInvalidName,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			svc := NewUserService()
			err := svc.CreateUser(tt.input)

			if (err != nil) != tt.wantErr {
				t.Errorf("CreateUser() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if tt.wantErr && err != tt.want {
				t.Errorf("CreateUser() error = %v, want %v", err, tt.want)
			}
		})
	}
}
```

## Integration Test with Testcontainers

```go
package integration

import (
	"context"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

func TestDatabaseIntegration(t *testing.T) {
	ctx := context.Background()

	// Start PostgreSQL container
	req := testcontainers.ContainerRequest{
		Image:        "postgres:15-alpine",
		ExposedPorts: []string{"5432/tcp"},
		Env: map[string]string{
			"POSTGRES_USER":     "test",
			"POSTGRES_PASSWORD": "test",
			"POSTGRES_DB":       "testdb",
		},
		WaitingFor: wait.ForLog("database system is ready to accept connections").
			WithOccurrence(2).
			WithStartupTimeout(60 * time.Second),
	}

	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		t.Fatalf("Failed to start container: %v", err)
	}
	defer container.Terminate(ctx)

	// Get connection details
	host, _ := container.Host(ctx)
	port, _ := container.MappedPort(ctx, "5432")

	// Run tests against container
	t.Run("CreateUser", func(t *testing.T) {
		db := connectToDatabase(host, port.Port())
		defer db.Close()

		user := User{Name: "Test", Email: "test@example.com"}
		err := db.CreateUser(user)
		if err != nil {
			t.Errorf("CreateUser() error = %v", err)
		}
	})
}
```

## Mocking with Interfaces

```go
package service

import (
	"testing"
)

// Repository interface for mocking
type UserRepository interface {
	GetByID(id string) (*User, error)
	Save(user *User) error
}

// Mock implementation
type MockUserRepository struct {
	GetByIDFunc func(id string) (*User, error)
	SaveFunc    func(user *User) error
}

func (m *MockUserRepository) GetByID(id string) (*User, error) {
	return m.GetByIDFunc(id)
}

func (m *MockUserRepository) Save(user *User) error {
	return m.SaveFunc(user)
}

func TestUserService_GetUser(t *testing.T) {
	expectedUser := &User{ID: "123", Name: "Test User"}

	mockRepo := &MockUserRepository{
		GetByIDFunc: func(id string) (*User, error) {
			if id == "123" {
				return expectedUser, nil
			}
			return nil, ErrNotFound
		},
	}

	svc := NewUserService(mockRepo)

	t.Run("existing user", func(t *testing.T) {
		user, err := svc.GetUser("123")
		if err != nil {
			t.Errorf("GetUser() error = %v", err)
		}
		if user.Name != expectedUser.Name {
			t.Errorf("GetUser() = %v, want %v", user.Name, expectedUser.Name)
		}
	})

	t.Run("non-existing user", func(t *testing.T) {
		_, err := svc.GetUser("999")
		if err != ErrNotFound {
			t.Errorf("GetUser() error = %v, want %v", err, ErrNotFound)
		}
	})
}
```

## Benchmark Tests

```go
package benchmark

import (
	"testing"
)

func BenchmarkUserCreation(b *testing.B) {
	svc := NewUserService()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		user := User{
			Name:  "Test User",
			Email: "test@example.com",
		}
		_ = svc.CreateUser(user)
	}
}

func BenchmarkUserLookup(b *testing.B) {
	svc := NewUserService()
	// Setup: create users
	for i := 0; i < 1000; i++ {
		svc.CreateUser(User{Name: "User", Email: "user@example.com"})
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = svc.GetUser("500")
	}
}
```
