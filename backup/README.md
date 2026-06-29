# script-debian

Collezione di script Bash per la gestione e manutenzione di sistemi Debian/Ubuntu.  
Progetto sviluppato nell'ambito del percorso ITS Academy — focus su automazione, logging e affidabilità.

---

## Struttura della repo

```
script-debian/
├── backup.sh       # Script principale di backup con compressione, verifica integrità e rotazione
├── gen.sh          # Script di supporto: genera file di test nella cartella sorgente
└── README.md
```

---

## backup.sh

Script di backup automatizzato che archivia una directory sorgente in formato `.tar.gz`, verifica l'integrità dell'archivio e gestisce la rotazione dei backup mantenendo solo gli ultimi N.

### Funzionalità

- Compressione della sorgente in `/tmp` come staging area
- Controllo spazio disponibile su `/tmp` e nella destinazione prima di procedere
- Pulizia automatica di `/tmp` se lo spazio è insufficiente (< 10 MB)
- Verifica integrità dell'archivio con `tar -tzf`
- Rotazione automatica: mantiene solo gli ultimi 3 backup
- Log dettagliato con timestamp su file giornaliero

### Configurazione

Modifica le variabili nella sezione `CONFIGURAZIONE` in cima allo script:

```bash
ORIGINE="/home/omar/lab/sorgente"       # Directory da backuppare
DESTINAZIONE="/home/omar/lab/destinazione"  # Dove salvare i backup
LOG_FILE="/home/omar/lab/logs/$(date +%Y%m%d)_log.txt"  # File di log giornaliero
```

### Utilizzo manuale

```bash
chmod +x backup.sh
./backup.sh
```

### Output atteso

Lo script produce un archivio nella cartella di destinazione con naming:

```
backup_20250615_143022.tar.gz
```

e un log nella cartella `logs/` con il dettaglio di ogni operazione.

---

## gen.sh

Script di supporto che genera un numero casuale (1-10) di file `.txt` nella directory sorgente, utile per testare `backup.sh` senza dover creare file manualmente.

### Utilizzo

```bash
chmod +x gen.sh
./gen.sh
```

---

## Automazione con cron

Per eseguire il backup in modo automatico e periodico, è possibile schedulare `backup.sh` tramite **cron**.

### Aprire il crontab

```bash
crontab -e
```

Al primo avvio, ti verrà chiesto quale editor usare. `nano` è il più semplice per chi inizia.

### Sintassi del crontab

```
* * * * * comando
│ │ │ │ │
│ │ │ │ └── giorno della settimana (0=domenica, 6=sabato)
│ │ │ └──── mese (1-12)
│ │ └────── giorno del mese (1-31)
│ └──────── ora (0-23)
└────────── minuto (0-59)
```

### Esempi pratici

```bash
# Ogni giorno alle 02:30
30 2 * * * /home/omar/script-debian/backup.sh

# Ogni domenica alle 03:00
0 3 * * 0 /home/omar/script-debian/backup.sh

# Ogni ora
0 * * * * /home/omar/script-debian/backup.sh

# Ogni giorno alle 02:30, con output degli errori salvato su file separato
30 2 * * * /home/omar/script-debian/backup.sh 2>> /home/omar/lab/logs/cron_errors.txt
```

### Verificare i job attivi

```bash
crontab -l
```

### Note importanti sul cron

**Usa sempre percorsi assoluti.** Cron gira in un ambiente minimale senza le variabili della tua shell (`$PATH`, `$HOME`, ecc.), quindi comandi come `./backup.sh` o path relativi non funzionano.

**Assicurati che lo script sia eseguibile:**
```bash
chmod +x /home/omar/script-debian/backup.sh
```

**Verifica che cron sia attivo sul sistema:**
```bash
sudo systemctl status cron
```

**Testa sempre lo script manualmente prima di schedularlo** per assicurarti che funzioni con i percorsi configurati.

**I log di sistema di cron** (utile per debug):
```bash
grep CRON /var/log/syslog
```

---

## Requisiti

- Bash 4+
- `tar`, `df`, `du`, `awk` (presenti di default su Debian/Ubuntu)
- Permessi di scrittura sulle directory `ORIGINE`, `DESTINAZIONE` e `logs/`

---

## Autore

**Omar Sabri** — [github.com/OmarSabri4](https://github.com/OmarSabri4)
