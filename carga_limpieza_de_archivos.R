# carga_limpieza_de_archivos.R
# Llamar las librerias
source("dependencias.R") # Source permite llamar las librerias en Dependencias
                          #sin necesidad de ir al archivo

# Crear un directorio de datos (en caso que no existe)
if (!dir.exists("datos")){
  dir.create("datos")
} else{
  print("El directorio existe")
}

#Descargar Datos del Padron Electoral y Lista Nominal

url <- "https://ine.mx/wp-content/uploads/2025/01/DatosAbiertos-derfe-pdln_edms_re_20250710.xlsx"

# Preparar el destino del archivo
destino <- glue("datos/",basename(url))

# Hacer la petición del INE usango la función GET de HTTR
response <- tryCatch(
  {
    res <- httr2::request(url) |>
      req_perform()
    
    
    if (resp_status(res) != 200) {
      message("Hubo un error: código HTTP ", resp_status_desc(res))
      NULL
    } else {
      message("Descarga exitosa.")
      res
    }
  },
  error = function(e) {
    message("Error de conexión o descarga: ", e$message)
    NULL
  }
)

if (!is.null(response)) {
  writeBin(httr2::resp_body_raw(response), destino)
}

datos <- read_xlsx(destino) |>
  head(-1) |> # La última linea trae TOTALES lo que genera una advertencia de lectura
  clean_names()

# Guardar datos en formato .parquet
fecha <- as.character(ymd(as_date(Sys.Date())))
destino_parquet <- glue("datos/",fecha,"_padron_por_sexo.parquet")
write_parquet(datos,destino_parquet)

# Leerlo después (más rápido y liviano)
df_arrow <- read_parquet(destino_parquet)


