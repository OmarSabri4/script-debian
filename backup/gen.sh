#!/bin/bash
set -e

ORIGINE="/home/omar/lab/sorgente"

# Se la cartella non esiste, creala
mkdir -p "$ORIGINE"

# Numero random da 1 a 10
N=$(( (RANDOM % 10) + 1 ))

echo "Genero $N file in $ORIGINE..."

for ((i=1; i<=N; i++)); do
    DATA=$(date +%Y%m%d_%H%M%S)
    FILE="$ORIGINE/file_${DATA}_$i.txt"
    echo "File generato automaticamente alle $(date)" > "$FILE"
    echo "Creato: $FILE"
    sleep 1
done

echo "Operazione completata."
