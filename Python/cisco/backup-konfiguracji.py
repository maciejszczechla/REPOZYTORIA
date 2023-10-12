#!/usr/bin/python3
import paramiko
import datetime

# Parametry pracy klienta SSH
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# Ustanowienie połączenia z routerem
client.connect(hostname='cisrt1001.blacklan.local', username='mszczechla', password='Makofinal10')

# Wykonanie polecenia "show running-config" i zapisanie wyniku w zmiennej
stdin, stdout, stderr = client.exec_command('show running-config')
stdin.close()
config = stdout.read().decode()

# Zamknięcie sesji SSH
client.close()

# Utworzenie nazwy pliku, w którym zostanie zapisana konfiguracja, na podstawie daty i czasu
now = datetime.datetime.now()
filename = f"konfiguracja-{now.year}-{now.month}-{now.day}-{now.hour}-{now.minute}.txt"

# Zapisanie danych do pliku
with open(filename, 'w') as f:
    f.write(config)
