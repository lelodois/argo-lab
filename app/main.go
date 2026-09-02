// billing-lab: app didática que imita o formato do billing da Cora no
// laboratório de Argo CD. Tudo é chaveável por env pra TREINAR incidentes:
//   APP_VERSION   — aparece na home (prova visual do deploy)
//   HEALTHY       — "false" => /health devolve 500 (simula Degraded)
//   SLOW_START_S  — segundos até o /health passar (simula Progressing longo)
package main

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"
)

var inicio = time.Now()

func main() {
	versao := getenv("APP_VERSION", "dev")
	slow, _ := strconv.Atoi(getenv("SLOW_START_S", "0"))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "💳 billing-lab %s — no ar há %s\n", versao, time.Since(inicio).Round(time.Second))
	})
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if getenv("HEALTHY", "true") == "false" {
			http.Error(w, "unhealthy (HEALTHY=false)", 500)
			return
		}
		if time.Since(inicio) < time.Duration(slow)*time.Second {
			http.Error(w, "warming up", 503)
			return
		}
		fmt.Fprintln(w, "ok")
	})
	fmt.Println("billing-lab", versao, "ouvindo :8080")
	_ = http.ListenAndServe(":8080", nil)
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
