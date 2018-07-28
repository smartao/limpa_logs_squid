#!/bin/bash
# 
# Script de limpeza de logs - 13/03/08
# Funcoes:
#	1 - LIMPAR CACHE
#		Limpa o cache do squid
#	2 - COMPACTAR
#		Compacta o arquivo de log do squid
#		move o arquivo para a pasta /tmp		
#	3 - COPIAR 
#		Copia o arquivo access.log do servidor para o servidor SPSERVERMON na /tmp/
#	4 - DESCOMPACTAR
#		Descompacta o arquivo na pasta /tmp do SPSERVERMON
#		coloca a data que foi gerado como sufixo no nome do arquivo 
#		move o arquivos para a pasta com o nome do site e com a data de
#	5 - DELETAR
#		Deleta os arquivos gerados na pasta /tmp 
#		deleta o access.log de todos os servidores
#	6 - EMAIL
#		Envia e-mail com o log do script 
# 		arquivo de conifguração: emails.conf	
function MAIN()
{
STOP_SQUID
COMPACTAR
}

function STOP_SQUID()
{
	echo "invoke-rc.d squid stop" | ssh 10.2.97.203 -p 2222 >>teste.log
}

function COMPACTAR()
{
	echo "saiu"
}

MAIN