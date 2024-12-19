# Configuración

Es increíblemente fácil -

![image](https://github.com/user-attachments/assets/0dc45d28-e190-44fb-9e8c-c550d3ed8360)



La configuración se realiza en dos pasos:
1. Github primero creará un codespace
2. Una vez que se inicializa el codespace (verá la interfaz de usuario de VSCode), se ejecuta un script que:
1. Crea un banco con la rama de desarrollo de Frappe y lo configura
2. Crea un nuevo sitio llamado dev.localhost con la contraseña `admin`
3. Habilita el modo de desarrollador, establece dev.localhost como sitio predeterminado

# Características

1. Se inicializa un banco nuevo con el último código de desarrollo de Frappe junto con un nuevo sitio cuando se crea inicialmente el codespace
1. `launch.json` preconfigurado con las siguientes opciones:
1. Servidor web
2. 3 trabajadores
3. Banco Observar
2. Extensiones preinstaladas
3. [SQLTools](https://marketplace.visualstudio.com/items?itemName=mtxr.sqltools) preconfiguradas

# Notas

- El script de inicio lleva un tiempo, por lo que puede realizar un seguimiento del progreso seleccionando "Codespaces : View Creation Log" en la paleta de comandos. Lo ideal es esperar hasta que se complete este proceso.
- El archivo Procfile generado incluye `bench serve`, por lo que `bench start` funcionará como siempre; sin embargo, si desea utilizar el depurador, debe eliminar la línea `bench serve` en el archivo Procfile y ejecutar `Bench Web` desde VSCode en su lugar
- He configurado los ajustes para que la extensión de Python apunte al Python correcto en el venv de forma predeterminada; sin embargo, si tiene problemas con el mal comportamiento del linter de VSCode o las opciones de inicio no funcionan (frappe no encontrado), verifique qué binario de Python está utilizando VSCode
- Github Codespaces funciona con la versión nativa de VSCode para una experiencia prácticamente nativa; solo necesita instalar la extensión Codespaces y configurarla para que se conecte a su Codespace. Recomiendo hacer esto en lugar de usar el navegador.
