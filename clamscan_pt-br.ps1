#Português-Brasil﻿
#Criado por Daniel Amorim

#Tirar a Restrição de Execução de Script PowerShell no usuário atual
Set-ExecutionPolicy Unrestricte -Scope CurrentUser

# Define as variáveis

# Diretório para os arquivos de log
$logDir = "C:\Program Files (x86)\ClamAV\logs" 

# Obtém a data e hora atual no formato Dia-Mês-Ano_Hora_minuto
$timestamp = Get-Date -Format dd-MM-yyyy_HH-mm

# Cria o nome do arquivo de log com o timestamp
$logFile = Join-Path $logDir "scan_$timestamp.log"

# Caminho para a pasta a ser escaneada
$scanPath = "C:\Users" 

$clamscanPath = "C:\Program Files (x86)\ClamAV\clamscan.exe" # Caminho para o executável clamscan
$DatabaseDir = "C:\Program Files (x86)\ClamAV\database" # Caminho para Base de Dados
$TempDir = "C:\Program Files (x86)\ClamAV\quarantine" # Caminho para arquivos Temporários em Quarentena
$freshclamPath = "C:\Program Files (x86)\ClamAV\freshclam.exe" # Atualização da Base de Dados

#Define o nome da Tarefa Agendada a ser criada
$TaskName = "ClamScanTask"


# Verifica e cria diretórios
$dirs = @($logDir, $TempDir, $DatabaseDir)
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir
    }
}

#Verifica se Tarefa Agendada "ClamScanTask" existe, se não existir criar
$task = Get-ScheduledTask

if ($task.TaskName -eq  $TaskName) { 
               
           try {
                  # Obtém a data e hora atual no formato dd-MM-yyyy_HH-mm
                $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm 
                $timeStart = Get-Date -Format HH:mm
                # Cria o nome do arquivo de log com o timestamp
                $logFile = Join-Path $logDir "scan_$timestamp.log" 
               
                schtasks /CHANGE /TR "'$clamscanPath' -r -i -o '$scanPath'  --database='$DatabaseDir' --move='$TempDir' --log='$logFile' " /RU SYSTEM /ST $timestart  /TN "$TaskName" 
               
                # Obtém a data e hora atual no formato dd-MM-yyyy_HH-mm
                $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm-ss 
                $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
                Write-Host  "A tarefa $TaskName existe. -- $timestamp"
                Write-Host  "Tarefa $TaskName EDITADA com sucesso. -- $timestamp"                  
                echo "A tarefa $TaskName existe. -- $timestamp" | Out-File -FilePath $logTaskFile -Append
                echo "Tarefa $TaskName EDITADA com sucesso. -- $timestamp" | Out-File -FilePath $logTaskFile -Append
                 
                  }

            catch {
            
                # Obtém a data e hora atual no formato dd-MM-yyyy_HH-mm
                $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
                $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
                Write-Host  "ERRO ao editar a tarefa $TaskName -- $timestamp " 
                echo  "ERRO ao editar a tarefa $TaskName -- $timestamp - "| Out-File -FilePath $logTaskFile -Append 
                
                   }       

}


if (!($task.TaskName -eq $TaskName))  {

            try {
                schtasks /create /sc hourly  /mo 21 /tn $TaskName /RU SYSTEM /tr "'$clamscanPath' -r -i -o '$scanPath'  --database='$DatabaseDir' --move='$TempDir' --log='$logFile' "
                # Obtém a data e hora atual no formato dd-MM-yyyy_HH-mm
                 # Obtém a data e hora atual no formato dd-MM-yyyy_HH-mm
                $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
                $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
                Write-Host  "Tarefa $TaskName CRIADA com sucesso. -- $timestamp"
                echo  "Tarefa $TaskName CRIADA com sucesso. -- $timestamp" | Out-File -FilePath $logTaskFile -Append
                
                     }

            catch {
                 $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
                $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
                Write-Host "ERRO ao criar a tarefa $TaskName -- $timestamp"
                echo  "ERRO ao criar a tarefa $TaskName -- $timestamp - " | Out-File -FilePath $logTaskFile -Append # Inclui a mensagem de erro
                
            }
            
        }

#New-Item -Path "C:\Program Files (x86)\ClamAV\logs\freshclam_$timestamp.log" -ItemType File -Force                            
$timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
$logDatabaseFile = Join-Path $logDir "log_database_update_$timestamp.txt"

# Executa o Update da Base
& $freshclamPath --datadir=$DatabaseDir --log=$logDatabaseFile  

# Verifica se houve erros
if ($LastExitCode  -ne 0) {
                            $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
                            echo "ERRO durante a ATUALIZACAO da BASE. -- $timestamp $_ " | Out-File -FilePath $logDatabaseFile -Append
                           }


#Principais Comandos
#-r Recursive
#-i Only print Infected files
#-o --suppress-ok-results           Skip printing OK files

# Executa o clamscan
& $clamscanPath -r -i -o $scanPath  --database=$DatabaseDir --move=$TempDir --log=$logFile 


#Cria uma pasta com os logs usando alguns dados da máquina - hostname e IP, útil para fazer o upload dos arquivos para um outro servidor, ESSA PARTE AINDA ESTÁ EM DESENVOLVIMENTO.
$hostname = hostname
$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -NotLike "Loopback Pseudo-Interface*"}  |Select-Object -ExpandProperty IPAddress 
$origem = "C:\Program Files (x86)\ClamAV\logs"
$destino = "C:\Program Files (x86)\ClamAV\logs\-$hostname-$ip"

if (!(Test-Path -Path $destino)) {
    New-Item -ItemType Directory -Path $destino | Out-Null
}

#Obtém todos os arquivos na pasta de origem
$arquivos = Get-ChildItem -Path $origem -File 

# Loop para copiar cada arquivo
foreach ($arquivo in $arquivos) {
    $destinoArquivo = Join-Path -Path $destino -ChildPath $arquivo
    Copy-Item -Path $arquivo.FullName -Destination $destinoArquivo
}


# Verifica se houve erros
#if ($LastExitCode -ne 0) {
#                           $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
#                           echo "ERRO durante o escaneamento. -- $timestamp $_ " | Out-File -FilePath $logFile -Append
#}
	 
break                         
#Devolver a Restrição de Execução de Script PowerShell no usuário atual
Set-ExecutionPolicy Restrict -Scope CurrentUser
