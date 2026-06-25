#!/bin/bash
set -e

# ============================
# CONFIGURAZIONE
# ============================
ORIGINE="/home/omar/lab/sorgente"
DESTINAZIONE="/home/omar/lab/destinazione"
LOG_FILE="/home/omar/lab/logs/log.txt"

DATA=$(date +%Y%m%d_%H%M%S)
NOME_FILE="backup_${DATA}.tar.gz"
TMP_FILE="/tmp/$NOME_FILE"

# ============================
# FUNZIONE LOG
# ============================
scrivi_log() {
    printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

# ============================
# CREAZIONE CARTELLE
# ============================
mkdir -p "$ORIGINE"
mkdir -p "$DESTINAZIONE"

scrivi_log "INIZIO PROCESSO BACKUP"

# ============================
# CONTROLLO SPAZIO SU /TMP
# ============================
scrivi_log "Controllo spazio su /tmp..."

TMP_FS=$(df -P /tmp | tail -1 | awk '{print $1}')
TMP_DISPONIBILE_KB=$(df -P | grep "$TMP_FS" | head -n 1 | awk '{print int($4)}')

# Se /tmp ha meno di 10MB → pulizia
if [ "$TMP_DISPONIBILE_KB" -lt 10240 ]; then
    scrivi_log "ATTENZIONE: /tmp quasi piena, pulizia in corso..."
    rm -rf /tmp/* || true
fi

# Ricalcolo dopo pulizia
TMP_DISPONIBILE_KB=$(df -P | grep "$TMP_FS" | head -n 1 | awk '{print int($4)}')

if [ "$TMP_DISPONIBILE_KB" -lt 10240 ]; then
    scrivi_log "ERRORE: /tmp non ha spazio sufficiente."
    exit 1
fi

# ============================
# CONTROLLO SPAZIO DESTINAZIONE
# ============================
scrivi_log "Controllo spazio su disco destinazione..."

# Spazio richiesto in KB
SPAZIO_RICHIESTO_KB=$(du -s "$ORIGINE" | head -n 1 | awk '{print int($1)}')

# Filesystem della destinazione
FS=$(df -P "$DESTINAZIONE" | tail -1 | awk '{print $1}')

# Spazio disponibile in KB (solo prima riga)
SPAZIO_DISPONIBILE_KB=$(df -P | grep "$FS" | head -n 1 | awk '{print int($4)}')

# Conversione in MB
SPAZIO_DISPONIBILE_MB=$(( SPAZIO_DISPONIBILE_KB / 1024 ))

# Log pulito
scrivi_log "Spazio disponibile in destinazione: ${SPAZIO_DISPONIBILE_MB} MB"

# Confronto
if [ "$SPAZIO_RICHIESTO_KB" -gt "$SPAZIO_DISPONIBILE_KB" ]; then
    scrivi_log "ERRORE: spazio insufficiente sul disco di destinazione."
    exit 1
fi

# ============================
# CREAZIONE ARCHIVIO IN /TMP
# ============================
scrivi_log "Creazione archivio in /tmp..."

DIR_PADRE=$(dirname "$ORIGINE")
NOME_DIR=$(basename "$ORIGINE")

if tar -czf "$TMP_FILE" -C "$DIR_PADRE" "$NOME_DIR" 2>> "$LOG_FILE"; then
    scrivi_log "Archivio creato correttamente in /tmp."
else
    scrivi_log "ERRORE: creazione archivio fallita."
    exit 1
fi

# ============================
# VERIFICA INTEGRITÀ
# ============================
scrivi_log "Verifica integrità archivio..."

if tar -tzf "$TMP_FILE" > /dev/null 2>> "$LOG_FILE"; then
    scrivi_log "Archivio integro."
else
    scrivi_log "ERRORE: archivio corrotto!"
    rm -f "$TMP_FILE"
    exit 1
fi

# ============================
# SPOSTAMENTO FINALE
# ============================
scrivi_log "Spostamento archivio nella destinazione..."

mv "$TMP_FILE" "$DESTINAZIONE" || {
    scrivi_log "ERRORE: impossibile spostare l'archivio."
    exit 1
}

scrivi_log "FINE PROCESSO — BACKUP COMPLETATO"
exit 0
