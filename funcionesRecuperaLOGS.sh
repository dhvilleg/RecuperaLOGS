#!/bin/sh
#trap '' 2
alias echo="echo -e"
HOME="/scripts/logsBuses"
OSTYPE=`uname -s`
LOGDIR="/backup/LOGS"
LOGTMP="$HOME/LOGS"
SERVICIO="$HOME/buses.conf"
GLOBAL_ENV="$HOME/global.conf"
#funcion para evaluar la salida del check
crea_busqueda () {
    HOSTNAME="$1"
    LOGTYPE="$2"
    DATE_EVAL="$3"
    TARGET=`ssh usrphpsx@$HOSTNAME ls -lart $LOGDIR/$HOSTNAME.$LOGTYPE.$DATE_EVAL* | awk '{print $9}'`
    if [ -z "$TARGET" ]
    then
        >$HOME/busqueda.tmp
    else
        CONT=1
        >$HOME/busqueda.tmp
        for e in `echo $TARGET`;
        do
            echo "$CONT:$e">>$HOME/busqueda.tmp
            let CONT=CONT+1
        done
    fi
}

genera_busqueda () {
    ORDEN="$1"
    SEARCH_FILE="$HOME/busqueda.tmp"
    if [ -s "$SEARCH_FILE" ]
    then
        for e in `echo $ORDEN`;
        do
        CONT=1
            for i in `cat $SEARCH_FILE |awk -F: '{print $2}'`;
            do
                if [ $CONT -eq $e ]
                then
                    ENCUENTRA="$i\n$ENCUENTRA"
                fi
                let CONT=CONT+1
            done
        done
    else
        echo 1
    fi
    echo $ENCUENTRA
}

accion_busqueda () {
    ORDEN="$2"
    SERVER="$1"
    HOST_FTP='X.X.X.X'
    USER='uio\opcencom'
    PASSWD='password'
    FTP_DIR="/Dir/FTP"
    for e in `echo $ORDEN`;
    do
        scp usuario@$SERVER:$e $LOGTMP
    done
    lftp ftp://$USER:$PASSWD@$HOST_FTP -e "mirror -e -R $LOGTMP $FTP_DIR ; quit"
    rm -f $LOGTMP/*.gz

}

read_main () {
	SERVER="$2"
    choice=""
    fecha=""
    VARLOG=""
    VAR_BUSCA=""
    SEARCH_FILE="$HOME/busqueda.tmp"
    WORK_FILE=`cat $GLOBAL_ENV |grep $1| awk -F: '{print $4}'`
    LINEAS=`cat $WORK_FILE | wc -l`
    echo "Enter choice [ 0 - $LINEAS] "
    read  choice
    if [ $choice -ge 0 ] && [ $choice -le $LINEAS ];
    then
        if [ $choice -eq 0 ];
        then
            exit 0;
        fi

        for i in `cat $WORK_FILE |awk -F: '{print $2}'`;
        do
            if [ $CONT -eq $choice ]
            then
                VARLOG="$i"
            fi
            let CONT=CONT+1
        done
		
        clear
        while true
        do
            echo "buscando logs $VARLOG\nIngrese patron de fecha de busqueda, formato YYMMDDhhmm \npatrones validos 201906 , 20190623 , 20190615 , 2019061545 \nen caso de no ingresar patron de fechas buscara todos los archivos \n\n"
            echo "*** Presione v para volver al menu anterior ****\n"
            read fecha
            if [ -z $fecha ];
            then
                    clear
                    echo "*** error, no se ha ingresado nada ***"
            else
                if [ "$fecha" == "v" ]
                then
                        break
                fi
                crea_busqueda $SERVER $VARLOG $fecha
                while true
                do
                    if [ -s "$SEARCH_FILE" ];
                    then
                        echo "se han encontrado las siguientes coincidencias:\n"
                        cat $SEARCH_FILE
                        echo "\n\n ingrese los numeros de los archivos que desea recuperar separado por espacio. O presione r para repetir la busqueda o 0 para terminar: "
                        read VAR_BUSCA
                        if [ "$VAR_BUSCA" == "r" ]
                        then
                            break
                        fi
                        if [ "$VAR_BUSCA" == "0" ]
                        then
                            exit 0;
                        fi
                        GENERA=`genera_busqueda "$VAR_BUSCA"`
                        accion_busqueda $SERVER "$GENERA"
                    else
                        echo "No se han encontrado coincidencias, repita la busqueda"
                        break
                    fi
                done
            fi
        done
    else
        echo "${RED}Error fuera de rango...${STD}" && sleep 2
    fi

}

print_menu () {
    IMPRIME="$1"
    MENU="$2"
    clear
    echo "------------------- Ingresa el numero del $IMPRIME a buscar ----------------------\n\n\n"
    pr -2 $MENU | grep ":" | grep -v " Page "
    echo "\n\n-----------------------------------0.- Salir----------------------------------"
}

while true
do
    clear
    print_menu "SERVICIO" $SERVICIO
    LINEAS=`cat $SERVICIO | wc -l`
    echo "Enter choice [ 0 - $LINEAS] "
    read  choice
    if [ $choice -ge 0 ] && [ $choice -le $LINEAS ];
    then
        if [ $choice -eq 0 ];
        then
            exit 0;
        fi
            CONT=1
            for i in `cat $SERVICIO |awk -F: '{print $2}'`;
            do
                if [ $CONT -eq $choice ];
                then
                    SERVER=`cat $GLOBAL_ENV |grep $i|awk -F: '{print $3}'`;
                    print_menu $i $SERVER
                    LINEAS=`cat $SERVER | wc -l`
                    read  choice
                        if [ $choice -ge 0 ] && [ $choice -le $LINEAS ];
                        then
                            if [ $choice -eq 0 ];
                            then
                                exit 0;
                            fi
                                CONT=1
                                for e in `cat $SERVER |awk -F: '{print $2}'`;
                                do
                                    if [ $CONT -eq $choice ];
                                    then
                                        SRV_FILE=`cat $GLOBAL_ENV |grep $i|awk -F: '{print $4}'`;
                                        print_menu $i $SRV_FILE
                                        read_main $i $e
                                    fi
                                    let CONT=CONT+1
                                done
                        else
                                            cho "${RED}Error fuera de rango...${STD}" && sleep 2
                                fi
                fi
                let CONT=CONT+1
            done
    else
        echo "${RED}Error fuera de rango...${STD}" && sleep 2
    fi

    #read_main
done
