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
	DATA
	. /etc/scripts/limpa_logs/variaveis.conf
	. /etc/scripts/limpa_logs/servers.conf
	. /etc/scripts/limpa_logs/emails.conf

	echo -e "$ASSUNTO\n" > $CAMINHO_LOG/$ARQ_LOG
	echo "#----------------- INICIO - LIMPA_LOGS.SH - $DATA - $HORA ---------------#" >> $CAMINHO_LOG/$ARQ_LOG
	echo "" >> $CAMINHO_LOG/$ARQ_LOG
			
	for((i=1; i<=${#IP[@]}; i++));
	do
		SERVERNAME
		if [ $ERRO == 0 ];then
			echo "- - - - - - - SERVIDOR:$SERVER_NAME - - - - - - -" >> $CAMINHO_LOG/$ARQ_LOG
			echo "" >> $CAMINHO_LOG/$ARQ_LOG
			TESTE=1
			VERIFICA_ARQ
			if [ $RESULT == 0 ];then
				STOP_SQUID
				#LIMPA_CACHE
				COMPACTAR
				COPIAR	
				DESCOMPACTAR
				DELETAR
				START_SQUID
				if [ $DEBUG -eq 1 ];then
					echo "" >> $CAMINHO_LOG/$ARQ_LOG
					echo "- - - - - MODO DEBUG ATIVADO - - - - -" >> $CAMINHO_LOG/$ARQ_LOG
					echo "" >> $CAMINHO_LOG/$ARQ_LOG
					cat $CAMINHO_LOG/$ARQ_DEBUG >> $CAMINHO_LOG/$ARQ_LOG
					echo "" >> $CAMINHO_LOG/$ARQ_LOG
					echo "- - - - - - FIM DO DEBUG - - - - - -" >> $CAMINHO_LOG/$ARQ_LOG
					echo "" >> $CAMINHO_LOG/$ARQ_LOG
				fi	
			fi
			echo "" >> $CAMINHO_LOG/$ARQ_LOG
			echo "- - - - - - - - - - CONCLUIDO - - - - - - - - - -" >> $CAMINHO_LOG/$ARQ_LOG
			echo "" >> $CAMINHO_LOG/$ARQ_LOG
		fi
		if [ $ERRO == 1 ];then
			#echo "STATUS: ***Falha***" >> $CAMINHO_LOG/$ARQ_LOG
			#echo "OBS.  : Erro ao conectar o servidor ${IP[$i]}, site ${SITE[$i]}" >> $CAMINHO_LOG/$ARQ_LOG
			CHECK="(    )"
			ACAO="Erro ao conectar o servidor ${IP[$i]}, site ${SITE[$i]}"
			echo "$TESTE - $CHECK - $HORA - $ACAO" >> $CAMINHO_LOG/$ARQ_LOG
			echo "" >> $CAMINHO_LOG/$ARQ_LOG
		fi
	done
	DATA	
 	echo "#-------------------- FIM - LIMPA_LOGS.SH - $DATA - $HORA ---------------#" >> $CAMINHO_LOG/$ARQ_LOG
	for ((e=1; e<=${#DESTINATARIO[@]}; e++));
	do
		$ESOFTWARE $REMETENDE ${DESTINATARIO[$e]} < $CAMINHO_LOG/$ARQ_LOG
	done
}

function SERVERNAME()
{
	DATA
	T=0
	TENTATIVAS=5
	while [ $T -lt $TENTATIVAS ];
	do
		let T=$T+1
		SERVER_NAME=`snmpwalk -v 1 -c public ${IP[$i]} .1.3.6.1.2.1.1.5 | cut -c31-50` >> /dev/null #$CAMINHO_LOG/$ARQ_DEBUG
                test -z $SERVER_NAME
                if [ $? == 0 ];then
			sleep 60                        
                else
			break; # Sair quando houver sucesso na coleta do hostname
                fi
        done
        if [ $T == $TENTATIVAS ];then
		ERRO=1
        fi
}
function STOP_SQUID()
{
	echo "invoke-rc.d squid stop" | ssh ${IP[$i]} -p $PORTA >> $CAMINHO_LOG/$ARQ_DEBUG
}

function START_SQUID()
{
	echo "invoke-rc.d squid start" | ssh ${IP[$i]} -p $PORTA >> $CAMINHO_LOG/$ARQ_DEBUG # starta o squid
}

function COMPACTAR()
{
	echo "cat $CAMINHO_ORI/$ARQ_ORI.* >> $CAMINHO_ORI/$ARQ_ORI" | ssh ${IP[$i]} -p $PORTA >> /dev/null # $CAMINHO_LOG/$ARQ_DEBUG
	echo "tar -vzcf $ARQ_ORI.tar.gz $CAMINHO_ORI/$ARQ_ORI" | ssh ${IP[$i]} -p $PORTA >> /dev/null # $CAMINHO_LOG/$ARQ_DEBUG
	TESTE=2
	VERIFICA_ARQ	
	
	echo "mv $ARQ_ORI.tar.gz $CAMINHO_TEMP" | ssh ${IP[$i]} -p $PORTA >> /dev/null # $CAMINHO_LOG/$ARQ_DEBUG
	TESTE=3
	VERIFICA_ARQ
}

function COPIAR()
{
	scp -P $PORTA ${IP[$i]}:$CAMINHO_TEMP/$ARQ_ORI.tar.gz $CAMINHO_TEMP # $CAMINHO_LOG/$ARQ_DEBUG
	TESTE=4
	VERIFICA_ARQ
}

function DESCOMPACTAR()
{
	tar -vzxf $CAMINHO_TEMP/$ARQ_ORI.tar.gz -C $CAMINHO_TEMP >> $CAMINHO_LOG/$ARQ_DEBUG
	TESTE=5
	VERIFICA_ARQ

	TESTE=6
	VERIFICA_ARQ
	
	mv -v $CAMINHO_TEMP$CAMINHO_ORI/$ARQ_ORI $CAMINHO_DEST/${SITE[$i]}/$ARQ_ORI-$DATA >> $CAMINHO_LOG/$ARQ_DEBUG
	TESTE=7
	VERIFICA_ARQ
}

function DELETAR()
{
	echo "rm $CAMINHO_ORI/$ARQ_ORI" | ssh ${IP[$i]} -p $PORTA >> /dev/null #$CAMINHO_LOG/$ARQ_DEBUG # Deletando access.log # padrao OK
	echo "rm -f $CAMINHO_ORI/$ARQ_ORI.*" | ssh ${IP[$i]} -p $PORTA >> /dev/null #$CAMINHO_LOG/$ARQ_DEBUG # Deletando access.log do logrotate .1 .2 .3 etc.
	echo "rm /root/$ARQ_ORI.tar.gz" | ssh ${IP[$i]} -p $PORTA >> /dev/null #$CAMINHO_LOG/$ARQ_DEBUG #Deletando arquivo.tar
	echo "rm $CAMINHO_TEMP/$ARQ_ORI.tar.gz" | ssh ${IP[$i]} -p $PORTA >> /dev/null# #$CAMINHO_LOG/$ARQ_DEBUG #Deletando arquivo.gz
	echo "rm $CAMINHO_TEMP/$ARQ_SCRIPT" | ssh ${IP[$i]} -p $PORTA >> /dev/null #$CAMINHO_LOG/$ARQ_DEBUG #Deletando Script Temporario
	echo "rm $CAMINHO_TEMP/$ARQ_RESULT" | ssh ${IP[$i]} -p $PORTA >> /dev/null #$CAMINHO_LOG/$ARQ_DEBUG #Deletando Resultado do script

	echo "invoke-rc.d squid start" | ssh ${IP[$i]} -p $PORTA >> $CAMINHO_LOG/$ARQ_DEBUG # starta o squid # Remover

	rm -v $CAMINHO_TEMP/$ARQ_ORI.tar.gz >> $CAMINHO_LOG/$ARQ_DEBUG #Deletando arquivo compactado
	rm -v $CAMINHO_TEMP/$ARQ_SCRIPT >> $CAMINHO_LOG/$ARQ_DEBUG # Deletando Script temporario do servidor local
	rm -v $CAMINHO_TEMP/$ARQ_RESULT >> $CAMINHO_LOG/$ARQ_DEBUG # Deletando Resultado do script do servidor local
}

function DATA()
{
	DATA=`date "+%y-%m-%d"` >> /dev/null
	HORA=`date "+%H:%M:%S"` >> /dev/null
	SEGUNDOS=`date "+%S"` >> /dev/null
}

function VERIFICA_ARQ()
{
	case $TESTE in
		"1")
			CAMINHO_TESTE=$CAMINHO_ORI/
			ARQ_TESTE=$ARQ_ORI
			ACAO="Verificado se existe o arquivo $CAMINHO_TESTE$ARQ_TESTE"
			TIP=-f
			TESTE_ARQ
			;;	 
		"2")
			CAMINHO_TESTE="/root/"
			ARQ_TESTE=$ARQ_ORI.tar.gz
			ACAO="Compactado o arquivo $ARQ_ORI para .TAR.GZ local: $CAMINHO_TESTE$ARQ_TESTE"
			TIP=-f
			TESTE_ARQ
			;;
		"3")
			CAMINHO_TESTE=$CAMINHO_TEMP/
			ARQ_TESTE=$ARQ_ORI.tar.gz
			ACAO="Movido arquivo $ARQ_TESTE para a pasta $CAMINHO_TESTE"
			TIP=-f
			TESTE_ARQ
			;;
		"4")
			CAMINHO_TESTE=$CAMINHO_TEMP/
			ARQ_TESTE=$ARQ_ORI.tar.gz
			ACAO="Copiado o arquivo $CAMINHO_TESTE$ARQ_TESTE para o servidor: $HOSTNAME"
			TIP=-f
			TESTE_ARQ
			;;
		"5")
			CAMINHO_TESTE=$CAMINHO_TEMP/
			ARQ_TESTE=$ARQ_ORI.tar.gz
			ACAO="Descompactado arquivo $CAMINHO_TESTE$ARQ_TESTE"
			TIP=-f
			TESTE_ARQ
			;;
		"6")
			CAMINHO_TESTE=$CAMINHO_DEST/${SITE[$i]}/
			ARQ_TESTE=""
			ACAO="Verificado a existencia do diretorio de log $CAMINHO_TESTE"
			TIP=-d
			TESTE_ARQ
			;;
		"7")
			CAMINHO_TESTE=$CAMINHO_DEST/${SITE[$i]}/
			ARQ_TESTE=$ARQ_ORI-$DATA
			ACAO="Verificado a criacao do arquivo de log diario em $CAMINHO_TESTE$ARQ_TESTE"
			TIP=-f
			TESTE_ARQ
			;;
		*)
 			echo "#------------------------------------------------------------------------------#" >> $CAMINHO_LOG/$ARQ_LOG
			echo "#-------------- ERRO AO ATRIBUIR VALOR A VARIAVEL TESTE = $TESTE -------------------#" >> $CAMINHO_LOG/$ARQ_LOG
			echo "#----------------------- O SCRIPT SERA FINALIZADO -----------------------------#" >> $CAMINHO_LOG/$ARQ_LOG
			echo "#------------------------------------------------------------------------------#" >> $CAMINHO_LOG/$ARQ_LOG
			exit;
			;;
	esac
}
function TESTE_ARQ()
{
	#----
	echo '#!/bin/bash' > $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo '#' >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo 'T=1' >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo "[ $TIP $CAMINHO_TESTE$ARQ_TESTE ]" >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo 'T=$?' >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo 'if [ $T == 1 ];then' >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo "echo 1 > $CAMINHO_SCRIPT/$ARQ_RESULT" >> $CAMINHO_SCRIPT/$ARQ_SCRIPT # Erro
	echo 'else' >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	echo "echo 0 > $CAMINHO_SCRIPT/$ARQ_RESULT" >> $CAMINHO_SCRIPT/$ARQ_SCRIPT # Ok
	echo 'fi' >> $CAMINHO_SCRIPT/$ARQ_SCRIPT
	chmod 755 $CAMINHO_SCRIPT/$ARQ_SCRIPT
	#----
	if [ $TESTE -le 3 ];then
		scp -P $PORTA $CAMINHO_SCRIPT/$ARQ_SCRIPT ${IP[$i]}:$CAMINHO_SCRIPT >> $CAMINHO_LOG/$ARQ_DEBUG
		echo "$CAMINHO_SCRIPT/./$ARQ_SCRIPT" | ssh ${IP[$i]} -p $PORTA >> $CAMINHO_LOG/$ARQ_DEBUG # Executa o Script remotamente
	 	scp -P $PORTA ${IP[$i]}:$CAMINHO_SCRIPT/$ARQ_RESULT $CAMINHO_SCRIPT >> $CAMINHO_LOG/$ARQ_DEBUG
	fi
	if [ $TESTE -ge 4 ];then
		$CAMINHO_SCRIPT/./$ARQ_SCRIPT >> $CAMINHO_LOG/$ARQ_DEBUG
	fi
	
	RESULT=`cat $CAMINHO_SCRIPT/$ARQ_RESULT` >> $CAMINHO_LOG/$ARQ_DEBUG

	if [ $DEBUG -eq 1 ];then
		if [ $TESTE -ge 3 ];then
			if [ $TESTE -ne 3 ] && [ $TESTE -ne 6 ];then
				TAM=`ls -hs $CAMINHO_TESTE$ARQ_TESTE` >> $CAMINHO_LOG/$ARQ_DEBUG
				echo "TAMANHO DO ARQUIVO: $TAM" >> $CAMINHO_LOG/$ARQ_LOG
			fi
			echo "ESPACO:" >> $CAMINHO_LOG/$ARQ_LOG
			df -h | grep Tam >> $CAMINHO_LOG/$ARQ_LOG
			df -h | grep sd >> $CAMINHO_LOG/$ARQ_LOG
		fi	
	fi
	if [ $RESULT == 0 ];then
		CHECK="( x )"
	fi
	if [ $RESULT == 1 ];then
		CHECK="(    )"
		if [ $TIP == "-d" ];then
			ACAO="Diretorio $CAMINHO_TESTE nao encontrado, criado diretorio automaticamente." 
			mkdir -p $CAMINHO_TESTE >> $CAMINHO_LOG/$ARQ_DEBUG
		else
			ACAO="Arquivo $CAMINHO_TESTE$ARQ_TESTE nao encontrado."
		fi
	fi
	echo -e "$TESTE - $CHECK - $HORA - $ACAO" >> $CAMINHO_LOG/$ARQ_LOG
	DATA
	TESTE=0
}

MAIN
exit;
