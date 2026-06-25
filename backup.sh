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

# ============================
# FUNZIONE LOG
# ============================
scrivi_log() {
    printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

# ============================
# CONTROLLI PRELIMINARI
# ============================

# 1. Origine esiste?
if [ ! -d "$ORIGINE" ]; then
    printf "ERRORE: La cartella di origine %s non esiste.\n" "$ORIGINE" >&2
    exit 1
fi

# 2. Destinazione esiste? Se no, creala
if [ ! -d "$DESTINAZIONE" ]; then
    mkdir -p "$DESTINAZIONE" || {
        printf "ERRORE: Impossibile creare %s\n" "$DESTINAZIONE" >&2
        exit 1
    }
fi

scrivi_log "INIZIO PROCESSO BACKUP"

# ============================
# CONTROLLO SPAZIO SU DISCO
# ============================

scrivi_log "Verifica spazio su disco..."

# Spazio richiesto (in KB)
SPAZIO_RICHIESTO=$(du -s "$ORIGINE" | awk '{print int($1)}')

# Identifica il filesystem reale della destinazione
FS=$(df -P "$DESTINAZIONE" | tail -1 | awk '{print $1}')

# Spazio disponibile sul filesystem (in KB)
SPAZIO_DISPONIBILE=$(df -P | grep "$FS" | awk '{print int($4)}')

# Debug (puoi rimuoverli)
echo "RICHIESTO = $SPAZIO_RICHIESTO"
echo "DISPONIBILE = $SPAZIO_DISPONIBILE"

# Confronto numerico
if [ "$SPAZIO_RICHIESTO" -gt "$SPAZIO_DISPONIBILE" ]; then
    scrivi_log "ERRORE: Spazio insufficiente sul disco di destinazione."
    exit 1
fi

# ============================
# CREAZIONE ARCHIVIO
# ============================

scrivi_log "Creazione archivio..."

DIR_PADRE=$(dirname "$ORIGINE")
NOME_DIR=$(basename "$ORIGINE")

if tar -czf "$DESTINAZIONE/$NOME_FILE" -C "$DIR_PADRE" "$NOME_DIR" 2>> "$LOG_FILE"; then
    scrivi_log "Archivio creato con successo."
else
    scrivi_log "ERRORE: Creazione archivio fallita."
    exit 1
fi

# ============================
# VERIFICA INTEGRITÀ
# ============================

scrivi_log "Verifica integrità archivio..."

if tar -tzf "$DESTINAZIONE/$NOME_FILE" > /dev/null 2>> "$LOG_FILE"; then
    scrivi_log "Archivio integro."
else
    scrivi_log "ERRORE: Archivio corrotto!"
    exit 1
fi

# ============================
# FINE
# ============================

scrivi_log "FINE PROCESSO"
exit 0
