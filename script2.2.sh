#!/bin/bash

# Nombre del archivo
input_file="entrada.csv"
input_file_acciones="acciones.csv"

# Archivo de configuración
config_file="datos.conf"

# Archivos temporales
input_file2="temp.csv"
temp_file_utm="temp_utm.csv"
temp_file_locations="temp_locations.csv"
temp_file_tpp="temp_tpp.csv"
temp2_file_tpp="temp2_tpp.csv"
temp_file_tip="temp_tip.csv"
temp2_file_tip="temp2_tip.csv"
temp_file_cart="temp_cart.csv"

# Archivos de salida
utms_file="utms_file.txt"
locations_file="locations_file.txt"
output_file="resultados.txt"

if [ ! -f "$config_file" ]; then
    echo "El archivo $config_file no existe."
    exit 1
fi

# Leer el dato desde el archivo de configuración
storeid=$(grep -oP 'storeid: \K.*' "$config_file")

# Generar contenido de archivo de entrada
grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$input_file" > "$input_file2"


utms(){
	# Inicializar un archivo temporal para acumular todos los resultados
	> "$temp_file_utm"
	
	# Procesar todos los archivos entrada*.csv
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		# Lee la primera línea del archivo
		primera_fila=$(head -n 1 "$file")
		count_utms "$input_file2"
	done

	# Eliminar duplicados y contar las ocurrencias de textos únicos
	awk -F '\t' '{count[$1]++} END {for (text in count) print text, count[text]}' "$temp_file_utm" > "$utms_file"

	# Limpiar el archivo temporal
	rm "$temp_file_utm"
	rm "$input_file2"

	echo "Resultados acumulados y guardados en $utms_file"
}

count_utms() {
    local input_file="$1"

    # Inicializa las variables para almacenar los números de columna
    campaignMedium_columna=-1
    campaignName_columna=-1

    # Divide la línea en columnas usando el delimitador de tabulación y guarda el resultado en un array
    IFS=$'\t' read -r -a columnas <<< "$primera_fila"

    # Recorre las columnas para encontrar las posiciones deseadas
    for i in "${!columnas[@]}"; do
        if [ "${columnas[$i]}" == "campaignMedium" ]; then
            campaignMedium_columna=$((i+1))
        elif [ "${columnas[$i]}" == "campaignName" ]; then
            campaignName_columna=$((i+1))
        fi
    done

    # Valida que existan las columnas
    if [ $campaignMedium_columna -eq -1 ]; then
        echo "campaignMedium no se encontró en la primera fila de $input_file."
        exit 1
    fi

    if [ $campaignName_columna -eq -1 ]; then
        echo "campaignName no se encontró en la primera fila de $input_file."
        exit 1
    fi

    # Filtrar las columnas específicas y acumular en el archivo temporal
    awk -v last_col=$campaignMedium_columna -v first_col=$campaignName_columna -F '\t' '
        NR > 1 { print $(last_col) "\t" $(first_col) }
    ' "$input_file" >> "$temp_file_utm"
}

locations(){
	# Inicializar un archivo temporal para acumular todos los resultados
	> "$temp_file_locations"
	
	# Procesar todos los archivos entrada*.csv
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		# Lee la primera línea del archivo
		primera_fila=$(head -n 1 "$file")
		count_locations "$input_file2"
	done

	# Eliminar duplicados y contar las ocurrencias de textos únicos
	awk -F '\t' '{count[$1]++} END {for (text in count) print text, count[text]}' "$temp_file_locations" > "$locations_file"

	# Limpiar el archivo temporal
	rm "$temp_file_locations"
	rm "$input_file2"

	echo "Resultados acumulados y guardados en $locations_file"
}

count_locations() {
    local input_file="$1"

    # Inicializa las variables para almacenar los números de columna
    location_columna=-1

    # Divide la línea en columnas usando el delimitador de tabulación y guarda el resultado en un array
    IFS=$'\t' read -r -a columnas <<< "$primera_fila"

    # Recorre las columnas para encontrar las posiciones deseadas
    for i in "${!columnas[@]}"; do
        if [ "${columnas[$i]}" == "location" ]; then
            location_columna=$((i+1))
        fi
    done

    # Valida que existan las columnas
    if [ $location_columna -eq -1 ]; then
        echo "location no se encontró en la primera fila de $input_file."
        exit 1
    fi

    # Filtrar las columnas específicas y acumular en el archivo temporal
    awk -v col=$location_columna -F '\t' '
        NR > 1 { print $(col) }
    ' "$input_file" >> "$temp_file_locations"
}

# Función para calcular el total de usuarios que hicieron X acción
count_user() {
    search_text="$1"
	total_lines=0
	for file in entrada_*.csv; do
		total_lines_file=$(grep -cE "$search_text" "$file")
		total_lines=$(awk "BEGIN {print $total_lines + $total_lines_file}")
	done
    echo "$total_lines"
}

# Función para calcular el total de ocurrencias de X acción
count_occurrences() {
    search_text="$1"
	total_occurrences=0
	for file in entrada_*.csv; do
		total_occurrences_file=$(grep -o "$search_text" "$file" | wc -l)
		total_occurrences=$(awk "BEGIN {print $total_occurrences + $total_occurrences_file}")
	done
    echo "$total_occurrences"
}

# Función para calcular el total de usuarios que hicieron X acción
count_user_filtered() {
    search_text="$1"
	total_lines=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		total_lines_file=$(grep -cE "$search_text" "$input_file2")
		total_lines=$(awk "BEGIN {print $total_lines + $total_lines_file}")
	done
	rm "$input_file2"
    echo "$total_lines"
}

# Función para calcular el total de ocurrencias de X acción
count_occurrences_filtered() {
    search_text="$1"
	total_occurrences=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		total_occurrences_file=$(grep -o "$search_text" "$input_file2" | wc -l)
		total_occurrences=$(awk "BEGIN {print $total_occurrences + $total_occurrences_file}")
	done
	rm "$input_file2"
    echo "$total_occurrences"
}

count_user_total() {
	total_occurrences=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		total_occurrences_file=$(wc -l < "$input_file2")
		total_occurrences=$(awk "BEGIN {print $total_occurrences + $total_occurrences_file}")
	done
	rm "$input_file2"
	echo "$total_occurrences"
}

count_user_PDP() {
    additional_lines=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		additional_lines_file=$(grep -cE "click-product-detail|featured-product|click-img-product" "$input_file2")
		additional_lines=$(awk "BEGIN {print $additional_lines + $additional_lines_file}")
	done
	rm "$input_file2"
    echo "$additional_lines"
}

count_vistas_PDP() {
	vistas_pdp=0
	for file in entrada_*.csv; do
		total_click_product_detail=$(grep -o "click-product-detail" "$file" | wc -l)
		total_click_img_product=$(grep -o "click-img-product" "$file" | wc -l)
		total_featured_product=$(grep -o "featured-product" "$file" | wc -l)
		vistas_pdp=$((total_click_product_detail + total_click_img_product + total_featured_product + vistas_pdp))
	done
    echo "$vistas_pdp"
}

count_user_escritorio() {
	desktop_count=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		desktop_count_file=$(grep -c "Escritorio" "$input_file2")
		desktop_count=$(awk "BEGIN {print $desktop_count + $desktop_count_file}")
	done
	rm "$input_file2"
	echo "$desktop_count"
}

count_usuarios_mobile() {
	other_count=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		other_count_file=$(grep -cv "Escritorio" "$input_file2")
		other_count=$(awk "BEGIN {print $other_count + $other_count_file}")
	done
	rm "$input_file2"
	echo "$other_count"	
}

# Función para contar usuarios activos
count_active_users() {
    active_lines=0
	for file in entrada_*.csv; do
		grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$file" > "$input_file2"
		active_lines_file=$(grep -cE "like-local-animation|confirm-name-chat|InCall > Products|call-share-button" "$input_file2")
		active_lines=$(awk "BEGIN {print $active_lines + $active_lines_file}")
	done
	rm "$input_file2"
    echo "$active_lines"
}

count_products_cart() {
	# Filtrar las cuatro primeras columnas y guardar en el archivo de salida
	awk -F '\t' '{print $1 ";" $2 ";" $3 ";" $4}' "$input_file_acciones" > "$temp_file_cart"
	
	awk_result=$(awk -F';' '
	{
		split($1, arr, /\[/)
		gsub(/ /, "", arr[1])
		split(arr[2], arr2, /\]/)
		producto = arr2[1]
		
		print arr[1] ";" arr2[1] ";;" $4 "\n"
	}
	' "$temp_file_cart")
	
	# Iterar sobre las líneas de awk_result e imprimir las que contienen "add-product-to-cart"
	while IFS= read -r line; do
		if [[ $line == *"add-product-to-cart"* ]]; then
			value=$(echo "$line" | awk -F ';' '{print $4}')
			total_value=$((total_value + value))
			c=$((c + 1))
		fi
	done <<< "$awk_result"	
	
	rm "$temp_file_cart"
}

count_visitas_PDP() {
	# Extraer el nombre del producto entre los corchetes y listar junto con la cantidad de eventos
	awk_result=$(awk -F';' '
	{
		split($1, arr, /\[/)
		gsub(/ /, "", arr[1])
		split(arr[2], arr2, /\]/)
		producto = arr2[1]
		
		print arr[1] ";" arr2[1] ";;" $2 "\n"
	}
	' "$temp_file")

	# Iterar sobre las líneas de awk_result e imprimir las que contienen una vista de PDP
	while IFS= read -r line; do
		if [[ $line == *"featured-product"* ]]; then
			echo "$line" | awk -F '\t' '{print $2 ";;" $4}' >> "$output_file_products"
		fi
		if [[ $line == *"click-product-detail"* ]]; then
			echo "$line" | awk -F '\t' '{print $2 ";" $4}' >> "$output_file_products"
		fi
		if [[ $line == *"click-img-product-detail"* ]]; then
			echo "$line" | awk -F '\t' '{print $2 ";" $4}' >> "$output_file_products"
		fi
	done <<< "$awk_result"
}

calcular_countdown(){
	usuarios_countdown=$(count_user "https://live.gojiraf.ai/store/$storeid/event")
	total_visitas_countdown=$(count_occurrences "https://live.gojiraf.ai/store/$storeid/event")
	usuarios_calendarizaciones=$(count_user "add-to-calendar-button")
	total_calendarizaciones=$(count_occurrences "add-to-calendar-button")
}

countdown_consola(){
calcular_countdown

echo "Usuarios countdown: $usuarios_countdown
Visitas al countdown: $total_visitas_countdown
Usuarios que hicieron Calendarizaciones: $usuarios_calendarizaciones
Calendarizaciones del evento: $total_calendarizaciones 
"
}

calcular_metricas(){
usuarios_like=$(count_user_filtered "like-local-animation")
total_like_local_animation=$(count_occurrences_filtered "like-local-animation")
usuarios_chat=$(count_user_filtered "user-initialized-chat|click-button-enabled-chat")
usuarios_completaron_form=$(count_user_filtered "confirm-name-chat")
usuarios_productos=$(count_user_filtered "InCall > Products")
total_shares=$(count_occurrences_filtered "call-share-button")
total_usuarios=$(count_user_total)
usuarios_carritos=$(count_user_filtered "cart-initialized")
total_carritos_iniciados=$(count_occurrences_filtered "cart-initialized")
usuarios_checkout_pay_button=$(count_user_filtered "checkout-pay-button")
total_checkout_pay_button=$(count_occurrences_filtered "checkout-pay-button")
usuarios_cart_buy_button_to_checkout=$(count_user_filtered "cart-buy-button-to-checkout")
total_cart_buy_button_to_checkout=$(count_occurrences_filtered "cart-buy-button-to-checkout")
usuarios_activos=$(count_active_users)
usuarios_PDP=$(count_user_PDP)
total_vistas_PDP=$(count_vistas_PDP)
usuarios_escritorio=$(count_user_escritorio)
usuarios_mobile=$(count_usuarios_mobile)
usuarios_redirections=$(count_user_filtered "click-view-more-integration-light")
total_redirections=$(count_occurrences_filtered "click-view-more-integration-light")

if [[ $usuarios_redirections > 0 ]]; then
	usuarios_carritos="N/A"
	total_carritos_iniciados="N/A"
	usuarios_checkout="N/A"
	total_checkout="N/A"
else
	usuarios_redirections="N/A"
	total_redirections="N/A"
	if [[ $total_checkout_pay_button > $total_cart_buy_button_to_checkout ]]; then
		usuarios_checkout=$usuarios_checkout_pay_button
		total_checkout=$total_checkout_pay_button
	else
		usuarios_checkout=$usuarios_cart_buy_button_to_checkout
		total_checkout=$total_cart_buy_button_to_checkout
	fi
fi
}

mostrar_metricas(){
calcular_metricas
echo "Total de usuarios: $total_usuarios 
Usuarios activos: $usuarios_activos 
Usuarios Mobile: $usuarios_mobile 
Usuarios Desktop: $usuarios_escritorio 
Participantes en el chat: $usuarios_chat 
Usuarios que dieron Likes: $usuarios_like 
Click Likes Totales: $total_like_local_animation 
Click Share Totales: $total_shares 
Usuarios que vieron el detalle de producto: $usuarios_PDP 
Vistas detalle de producto: $total_vistas_PDP 
Usuarios que iniciaron carritos: $usuarios_carritos 
Carritos iniciados: $total_carritos_iniciados 
Usuarios que iniciaron Checkout: $usuarios_checkout 
Checkout iniciados: $total_checkout 
Redirecciones: $total_redirections 
Usuarios que hicieron redirecciones: $usuarios_redirections

"

}

calcular_tpps()
{	
	suma_diferencias=0
    contador=0
	# Procesar todos los archivos entrada*.csv
	for file in entrada_*.csv; do
		calcular_tpp "$file"
	done
	promedio=$(awk "BEGIN {print $suma_diferencias / $contador}")
	echo "$promedio"
}

calcular_tpp()
{
	local input_file="$1"
	
	# Lee la primera línea del archivo
	primera_fila=$(head -n 1 "$input_file")
	
	# Generar contenido de archivo de entrada
	grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$input_file" > "$temp2_file_tpp"
	
	line_count=$(wc -l < "$temp2_file_tpp")
	
	if [[ $line_count -gt 0 ]]; then
		# Inicializa las variables para almacenar los números de columna
		lastActionTimestamp_columna=-1
		firstActionTimestamp_columna=-1

		# Divide la línea en columnas usando el delimitador de coma y guarda el resultado en un array
		IFS=$'\t' read -r -a columnas <<< "$primera_fila"

		# Recorre las columnas para encontrar las posiciones deseadas
		for i in "${!columnas[@]}"; do
			if [ "${columnas[$i]}" == "lastActionTimestamp" ]; then
				lastActionTimestamp_columna=$((i+1))
			elif [ "${columnas[$i]}" == "firstActionTimestamp" ]; then
				firstActionTimestamp_columna=$((i+1))
			fi
		done

		# Valida que existan las columnas
		if [ $lastActionTimestamp_columna -eq -1 ]; then
			echo "lastActionTimestamp no se encontró en la primera fila de $input_file."
			exit 1
		fi

		if [ $firstActionTimestamp_columna -eq -1 ]; then
			echo "firstActionTimestamp no se encontró en la primera fila de $input_file."
			exit 1
		fi

		# Filtrar las columnas específicas y guardar en el archivo de salida
		awk -v last_col=$lastActionTimestamp_columna -v first_col=$firstActionTimestamp_columna -F '\t' '
			NR > 1 { print $(last_col) "\t" $(first_col) }
		' "$temp2_file_tpp" > "$temp_file_tpp"
		
		read suma cont < <(
			awk -F '\t' '
			  BEGIN { suma = 0; cont = 0 }
			  {
				diferencia = $1 - $2
				suma += diferencia
				cont++
			  }
			  END {
				if (cont > 0) {
				  print suma, cont
				} 
			  }
			' "$temp_file_tpp"
		)	
		suma_diferencias=$(awk "BEGIN {print $suma_diferencias + $suma}")
		contador=$(awk "BEGIN {print $cont + $contador}")
		rm "$temp_file_tpp"
	fi	
	rm "$temp2_file_tpp"
}

calcular_tips()
{	
	suma=0
    contador=0
	# Procesar todos los archivos entrada*.csv
	for file in entrada_*.csv; do
		calcular_tip "$file"
	done
	promedio=$(awk "BEGIN {print $suma / $contador}")
	echo "$promedio"
}

calcular_tip()
{
	local input_file="$1"
	
	# Lee la primera línea del archivo
	primera_fila=$(head -n 1 "$input_file")
	
	# Generar contenido de archivo de entrada
	grep -E "click-product-detail|featured-product|click-img-product|entered-live-event|like-local-animation|confirm-name-chat|call-share-button" "$input_file" > "$temp2_file_tip"
	
	line_count=$(wc -l < "$temp2_file_tip")
	
	if [[ $line_count -gt 0 ]]; then
	
		# Inicializar contador de columnas y número de columnas que contienen "timeSpent"
		columna_num=1
		columnas_con_timeSpent=()

		# Separar la primera línea por comas (o cambiar el delimitador según sea necesario)
		IFS=$'\t' read -ra columnas <<< "$primera_fila"

		# Recorrer cada columna y verificar si contiene "timeSpent"
		for columna in "${columnas[@]}"; do
			if [[ "$columna" == *"timeSpent"* && "$columna" != *Pretty* ]]; then
				columnas_con_timeSpent+=("$columna_num")
			fi
			((columna_num++))
		done

		# Crear una cadena con los números de las columnas separados por comas
		columnas_str=$(IFS=,; echo "${columnas_con_timeSpent[*]}")

		# Generar el CSV temporal con awk
		awk -v cols="$columnas_str" -F '\t' '
		BEGIN {
			split(cols, arr, ",");
		}
		NR == 1 {
			for (i in arr) {
				printf "%s%s", (i==1 ? "" : FS), $arr[i];
			}
			print "";
		}
		NR > 1 {
			for (i in arr) {
				printf "%s%s", (i==1 ? "" : FS), $arr[i];
			}
			print "";
		}' "$temp2_file_tip" > "$temp_file_tip"
		
		read total_sum total_rows < <(
			awk -F'\t' '
			BEGIN { total_sum = 0; total_rows = 0 }
			{
				row_sum = 0
				for (i = 1; i <= NF; i++) {
					row_sum += $i
				}
				total_sum += row_sum
				total_rows++
			}
			END {
				if (total_rows > 0) {
					print total_sum, total_rows
				} 
			}
			' "$temp_file_tip"
		)
		suma=$(awk "BEGIN {print $total_sum + $suma}")
		contador=$(awk "BEGIN {print $total_rows + $contador}")

		rm "$temp_file_tip"
	fi	
	rm "$temp2_file_tip"
}

calcular_tiempos(){
tpp=$(calcular_tpps)
tpp_minutos=$(awk "BEGIN {printf \"%d\", int($tpp / 60)}")
tpp_segundos=$(awk "BEGIN {printf \"%d\", $tpp % 60}")
tip=$(calcular_tips)
tip_minutos=$(awk "BEGIN {printf \"%d\", int($tip / 60)}")
tip_segundos=$(awk "BEGIN {printf \"%d\", $tip % 60}")
}

mostrar_tiempos() {
	calcular_tiempos
	echo "Tiempo de interacción promedio es: $tip_minutos minutos y $tip_segundos segundos
Tiempo de permanencia promedio es: $tpp_minutos minutos y $tpp_segundos segundos"
}

generar_archivo(){
	calcular_countdown
	count_products_cart
	calcular_metricas
	calcular_tiempos
	echo "CSV: $total_visitas_countdown,$total_usuarios,,$usuarios_activos,$usuarios_mobile,$usuarios_escritorio,,,,,,0:$tip_minutos:$tip_segundos,$total_calendarizaciones,$usuarios_chat,$usuarios_like,$total_like_local_animation,$total_shares,$c,$total_value,$usuarios_PDP,$total_vistas_PDP,$usuarios_carritos,$total_carritos_iniciados,$usuarios_checkout,$total_checkout,,,,,,,,$total_redirections,$usuarios_redirections,$usuarios_completaron_form,$usuarios_countdown,0:$tpp_minutos:$tpp_segundos" > "$output_file"
	echo "Los resultados se han guardado en $output_file"
}

# Menú interactivo
while true; do
    # Mostrar el menú
    clear
    echo "Seleccione una opción:"
    echo "1. Calcular UTMs"
    echo "2. Calcular usuarios countdown (consola)"
    echo "3. Metricas (consola)"
    echo "4. Tiempos (consola)"
    echo "5. Generar archivo de resultados"
	echo "6. Calcular ubicaciones"
    echo "9. Salir"
    read -p "Ingrese la opción deseada: " opcion

    case $opcion in
        1)
            utms
            ;;
        2)
            countdown_consola
            ;;
        3)
            mostrar_metricas
            ;;
        4)
            mostrar_tiempos
            ;;
        5)  
            generar_archivo
            ;;
		6)
			locations
			;;
        9)
            echo "Saliendo del programa."
            exit 0
            ;;
        *)
            echo "Opción no válida. Inténtelo de nuevo."
            ;;
    esac

    # Esperar a que el usuario presione una tecla para continuar
    read -n 1 -s -p "Presione cualquier tecla para continuar..."
done