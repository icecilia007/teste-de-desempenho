#!/bin/bash
# Executa toda a suíte de testes de desempenho k6 em sequência.
# Uso: bash run-all-tests.sh
# Resultado: arquivo resultados.txt com o log completo.

LOG_FILE="resultados.txt"

> "$LOG_FILE"

log() {
    echo "$@" | tee -a "$LOG_FILE"
}

cleanup() {
    if [ -n "$API_PID" ]; then
        kill "$API_PID" 2>/dev/null
        log ""
        log "API encerrada (PID: $API_PID)."
    fi
}
trap cleanup EXIT

log "========================================"
log "  SUÍTE DE TESTES DE DESEMPENHO - k6"
log "  Início: $(date)"
log "========================================"
log ""

if ! command -v k6 &>/dev/null; then
    log "ERRO: k6 não encontrado. Instale: sudo gpg -k && sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69 && echo 'deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main' | sudo tee /etc/apt/sources.list.d/k6.list && sudo apt-get update && sudo apt-get install k6"
    exit 1
fi

if ! command -v node &>/dev/null; then
    log "ERRO: Node.js não encontrado."
    exit 1
fi

log "Instalando dependências da API..."
( cd atividade && npm install --silent ) 2>&1 | tee -a "$LOG_FILE"

log ""
log "Iniciando API em background..."
node atividade/src/server.js > api.log 2>&1 &
API_PID=$!
sleep 5

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" != "200" ]; then
    log "ERRO: API não respondeu (HTTP $HTTP_CODE). Verifique api.log."
    exit 1
fi

log "API online (PID: $API_PID) — Health: HTTP $HTTP_CODE"
log ""

run_test() {
    local name="$1"
    local script="$2"
    local wait_after="${3:-0}"

    log ""
    log "========================================"
    log "  $name"
    log "  Script : $script"
    log "  Início : $(date)"
    log "========================================"

    k6 run "$script" 2>&1 | tee -a "$LOG_FILE"
    local k6_exit=${PIPESTATUS[0]}

    log ""
    log "  Fim    : $(date) | Exit code: $k6_exit"
    log "========================================"

    if [ "$wait_after" -gt 0 ]; then
        log ""
        log "Aguardando ${wait_after}s para a API recuperar antes do próximo teste..."
        sleep "$wait_after"
    fi
}

run_test "ETAPA 1 — SMOKE TEST"   "tests/smoke.js"   180
run_test "ETAPA 2 — LOAD TEST"    "tests/load.js"    600
run_test "ETAPA 3 — STRESS TEST"  "tests/stress.js"  600
run_test "ETAPA 4 — SPIKE TEST"   "tests/spike.js"   0

log ""
log "========================================"
log "  TODOS OS TESTES CONCLUÍDOS!"
log "  Fim: $(date)"
log "  Log salvo em: $(pwd)/$LOG_FILE"
log "========================================"
