# mde
Extract specific database from mysqldump file

Usage: mde.sh [OPTIONS]
```
  -?, --help         Display this help and exit.
  --version          Output version information and exit
  -i <file>          Local MySql dump file
  -l, --list         List the databases found in dump file
  -A, --databases    Extract all databases from dump file to separate files
  -d <db name>       Extract specific database from dump file
  -o <output>        File (-d) or Directory (-A) to save the database extracted
```