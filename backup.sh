#!/bin/bash

# --- BLOCCO DI SICUREZZA ---
# 'set -e' dice a Bash: "Se un comando fallisce con un errore, fermati subito".
# Evita che lo script continui a girare alla cieca se qualcosa va storto all'inizio.
set -e

# --- CONFIGURAZIONE (Variabili globali in MAIUSCOLO) ---
# La cartella piena di file da salvare
ORIGINE="/home/omar/lab/sorgente"       
# La cartella dove metteremo l'archivio finale
DESTINAZIONE="/home/omar/lab/destinazione"   
# Il diario di bordo dove segneremo cosa succede
LOG_FILE="/home/omar/lab/logs/log.txt" 

# Generiamo un timestamp (AnnoMeseGiorno_OreMinutiSecondi)
# Serve a dare un nome unico a ogni backup, evitando di sovrascrivere quelli vecchi.
DATA=$(date +%Y%m%d_%H%M%S)
NOME_FILE="backup_${DATA}.tar.gz"

# --- FUNZIONI CONDIVISE ---
# Creiamo una funzione per non dover riscrivere ogni volta la logica del log.
scrivi_log() {
    # 'printf' è una versione più moderna e stabile di 'echo'.
    # %s indica una stringa di testo. Il primo %s prende la data attuale, il secondo prende il messaggio ($1).
    # '>>' (append) aggiunge il testo in fondo al file di log senza cancellare il contenuto precedente.
    printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

# --- CONTROLLI PRELIMINARI (Prevenzione degli errori) ---

# 1. Controllo esistenza cartella di origine
# Il flag '-d' controlla se il percorso esiste ed è una vera directory (cartella).
# Il punto esclamativo '!' inverte il significato: "Se NON è una directory..."
if [ ! -d "$ORIGINE" ]; then
    # '>&2' devia questo messaggio di errore sullo Standard Error (il canale dei messaggi critici)
    printf "ERRORE: La cartella di origine %s non esiste.\n" "$ORIGINE" >&2
    exit 1 # Usciamo dallo script segnalando un fallimento (codice diverso da 0)
fi

# 2. Controllo esistenza cartella di destinazione (e creazione automatica)
if [ ! -d "$DESTINAZIONE" ]; then
    # Se la cartella non esiste, proviamo a crearla con 'mkdir -p' (crea anche le cartelle genitore se mancano).
    # L'operatore '||' (OR) dice: "Se il comando a sinistra fallisce, esegui il blocco a destra".
    mkdir -p "$DESTINAZIONE" || { printf "ERRORE: Impossibile creare %s\n" "$DESTINAZIONE" >&2; exit 1; }
fi

# Ora che la cartella di destinazione esiste sicuramente, possiamo inaugurare il log di oggi
scrivi_log "INIZIO PROCESSO AVANZATO"

# 3. Controllo dello spazio su disco
scrivi_log "Verifica spazio su disco in corso..."

# 'du -s' calcola la dimensione della cartella di origine in Kilobyte.
# '| awk {print $1}' prende solo il primo dato dell'output (il numero puro) e ignora il nome della cartella.
SPAZIO_RICHIESTO=$(du -s "$ORIGINE" | awk '{print $1}')

# 'df -P' analizza lo spazio del disco di destinazione (-P evita che l'output vada a capo se il nome del disco è lungo).
# 'tail -1' isola l'ultima riga dei dati.
# '| awk {print $4}' isola la quarta colonna, che corrisponde allo spazio ancora disponibile.
SPAZIO_DISPONIBILE=$(df -P "$DESTINAZIONE" | tail -1 | awk '{print $4}')

# '-gt' sta per "Greater Than" (Maggiore di). 
# Se lo spazio richiesto è maggiore di quello disponibile, blocchiamo tutto prima di intasare il server.
if [ "$SPAZIO_RICHIESTO -gt $SPAZIO_DISPONIBILE" ]; then
    scrivi_log "ERRORE: Spazio insufficiente sul disco di destinazione."
    exit 1
fi

# --- ESECUZIONE BACKUP (La fase attiva) ---
scrivi_log "Creazione archivio in corso..."

# STRATEGIA DI SICUREZZA TAR: Separazione del percorso.
# Se passiamo a tar un percorso assoluto (es. /home/utente/dati), tar si arrabbierà e salverà l'intera catena di cartelle.
# Isolando il "padre" e il "nome della cartella", faremo credere a tar di trovarsi già sul posto.
DIR_PADRE=$(dirname "$ORIGINE")   # Estrae la rotta (es: /home/utente)
NOME_DIR=$(basename "$ORIGINE")    # Estrae solo l'ultimo nome (es: dati)

# Eseguiamo il comando tar con le opzioni:
# -c (create: crea archivio), -z (gzip: comprimilo), -f (file: scrivi il risultato in un file)
# -C (change directory): Spostati temporaneamente nella cartella padre prima di iniziare a comprimere.
# '2>>' Prende gli eventuali messaggi di errore di tar e li sposta nel file di log per non sporcare lo schermo.
if tar -czf "$DESTINAZIONE/$NOME_FILE" -C "$DIR_PADRE" "$NOME_DIR" 2>> "$LOG_FILE"; then
    scrivi_log "SUCCESSO: Archivio creato."
    
    # --- VERIFICA DI INTEGRITÀ ---
    scrivi_log "Verifica integrità del file tar.gz..."
    
    # -t (list): Chiediamo a tar di leggere l'indice dei file dentro l'archivio appena creato.
    # Se l'archivio è corrotto, tar restituirà un errore.
    # '> /dev/null' Nasconde l'elenco dei file (non ci interessa vederlo a schermo, ci interessa solo se il comando fallisce).
    if tar -tzf "$DESTINAZIONE/$NOME_FILE" > /dev/null 2>> "$LOG_FILE"; then
        scrivi_log "VERIFICA SUPERATA: L'archivio è integro e pronto."
    else
        scrivi_log "ERRORE VERIFICA: L'archivio sembra corrotto!"
        exit 1
    fi
else
    scrivi_log "ERRORE: Compressione fallita."
    exit 1
fi

# --- CONCLUSIONE ---
scrivi_log "FINE PROCESSO"

# Restituiamo 0 al sistema operativo per confermare che tutto è andato liscio come l'olio
exit 0
