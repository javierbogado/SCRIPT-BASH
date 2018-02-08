#!/bin/bash

# Spizzirri Damian
# version 1 -- 2018-31-01

option[1]='Authentication'
option[2]='User'
option[3]='Client'
option[4]='Entity'
option[5]='Mov'
option[6]='Parametrizer'
option[7]='ImpCliToGC'
option[8]='ExpGCToEnt'

port[1]='8301'
port[2]='8304'
port[3]='8302'
port[4]='8303'
port[5]='8306'
port[6]='8305'
port[7]='8307'
port[8]='8308'


folder[1]='gestion-compartida-authenticator'
folder[2]='gestion-compartida-rest-user'
folder[3]='gestion-compartida-rest-client'
folder[4]='gestion-compartida-rest-entity'
folder[5]='gestion-compartida-mov'
folder[6]='gestion-compartida-parametrizer'
folder[7]='gestion-compartida-ftp'
folder[8]='gestion-compartida-export'

echo '******************************************************************************************'
echo '***** FISCKER v0.1 ***********************************************************************'
echo '******** by Spizzirri Damian *************************************************************'
echo '******************************************************************************************'
echo '******************************************************************************************'
echo '******************************************************************************************'
echo '*********** FIS disponibles **************************************************************'
echo '******************************************************************************************'
for i in ${!option[*]}; do
	echo "$i. ${option[$i]}" 
done
echo '----------------'
echo '0. Todos'

read -p 'Opcion(s): ' option_s

mvn_command='mvn clean pre-integration-test -Dfabric8.generator.from=registry.access.redhat.com/jboss-fuse-6/fis-java-openshift'

docker_filter_container='docker ps --filter="name=NAME"'
docker_run_command='docker run -p 0.0.0.0:PORT:8080 --name NAME --restart always -d IMAGEID'
docker_stop_command='docker stop CONTAINER'
docker_rm_command='docker rm CONTAINER'
docker_rmi_command='docker rmi IMAGEID -f'
docker_ps_command='docker ps'

function docker_stop_container(){
	name=${option[$1]}
	echo 'Se para el container ' ${option[$1]}
	local_docker_filter_container=`echo $docker_filter_container | sed "s/NAME/$name/g"`
	echo 'Filtro: '$local_docker_filter_container
	
	index=0
	delete=0
	for cadena in `eval $local_docker_filter_container`; do
		index=$(( $index + 1 ))
		if  [[ $index = 9 ]];then
			container=$cadena
		fi
		
		if  [[ $index = 10 ]];then
			image=$cadena
			delete=1
			break
		fi
		
	done
	
	if [[ $delete = 1 ]]; then
	
		local_docker_stop_command=`echo $docker_stop_command | sed "s/CONTAINER/$container/g"`
		local_docker_rm_command=`echo $docker_rm_command | sed "s/CONTAINER/$container/g"`
		local_docker_rmi_command=`echo $docker_rmi_command | sed "s/IMAGEID/$image/g"`
		echo '1ro: ' $local_docker_stop_command
		echo '2do: ' $local_docker_rm_command
		echo '3ro: ' $local_docker_rmi_command
		
		eval $local_docker_stop_command
		eval $local_docker_rm_command
		eval $local_docker_rmi_command
	else
		echo 'El container ' $name 'no existe'
	fi
}

function run_maven_command(){
	echo 'Preparando FIS: ' ${option[$i]}
	eval "cd ${folder[$i]}"
	eval $mvn_command
	eval "cd .."
	echo 'Imagen generada'
}

function start_container(){
	echo 'Iniciando contenedor' ${option[$i]}
	local_docker_run_command=$docker_run_command
	port=${port[$i]}
	name=${option[$i]}
	imageid=$2
	local_docker_run_command=`echo $local_docker_run_command | sed "s/PORT/$port/g"`
	local_docker_run_command=`echo $local_docker_run_command | sed "s/NAME/$name/g"`
	local_docker_run_command=`echo $local_docker_run_command | sed "s/IMAGEID/$imageid/g"`
	echo $local_docker_run_command			
	eval $local_docker_run_command	
	echo "Contenedor ${option[$i]}"
}

#********************************************************************************
#******************************** m | a | i | n *********************************
#********************************************************************************
if [[ $option_s =~ ^[0-9](,[0-9])*$ ]]; then
	if [[ $option_s = 0 ]]; then
		for i in ${!option[*]}; do
			if [[ $i == 1 ]]; then
				option_s=1
			else	
				option_s="$option_s,$i" 
			fi	
		done
	fi
	echo 'Opciones seleccionadas: ' $option_s
	array_options=$(echo $option_s | tr "," "\n")
	for i in $array_options; do
		echo "Opcion: $i"
		docker_stop_container $i
		run_maven_command $i
		read -p 'ID de la imagen: ' imageid
		start_container $i $imageid
		eval $docker_ps_command
	done
	exit	
else
		echo 'Input incorrecto'		
fi
