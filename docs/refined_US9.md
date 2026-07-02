## US9: Instalación desde ZIP de Release

**As a** usuario que quiere instalar o actualizar el skill `us-refinement`
**I want** que los instaladores (`install.ps1` y `install.sh`) descarguen y extraigan el último ZIP de release publicado en GitHub en lugar de copiar archivos locales
**So that** pueda instalar el skill de forma global sin necesidad de clonar todo el repositorio y garantizando que solo se instalen los archivos de producción.

### Acceptance criteria

**Scenario 1: Instalación global descarga el ZIP de GitHub**
- **Given** que ejecuto el instalador en modo global (sin la opción `-Local` o `--local`)
- **When** se inicia el proceso de instalación
- **Then** el script debe descargar el último ZIP de release (`us-refinement.zip`) desde las releases oficiales de GitHub, extraerlo en la carpeta centralizada `~/.hjagar/skills/us-refinement` y crear los enlaces simbólicos o junctions correspondientes para los agentes.

**Scenario 2: Fallo de red o descarga del ZIP**
- **Given** que no hay conexión a internet o el repositorio de GitHub no está accesible
- **When** intento realizar una instalación global
- **Then** el instalador debe capturar el error de red, informar al usuario con un mensaje claro y abortar la instalación de forma segura sin dejar archivos corruptos en la carpeta de destino.

**Scenario 3: Modo local mantiene enlaces directos al código fuente**
- **Given** que ejecuto el instalador con la opción `-Local` o `--local`
- **When** se inicia la instalación
- **Then** el script debe omitir la descarga de internet y crear directamente los junctions o enlaces simbólicos apuntando al directorio de origen local, manteniendo el comportamiento actual para desarrollo.

### Dependencies
- **US7: Automatización de Releases (Release/Publish)**

### Technical scope
- Backend: Sí (modificar `install.ps1` e `install.sh` en la raíz del repositorio).
- Frontend: No.

### Assumptions / pending
- El instalador utilizará la URL de descarga directa de la última release: `https://github.com/hjagar/us-refinement/releases/latest/download/us-refinement.zip`.

<!-- [AI-DATA]
id: US9
type: feat
breaking: false
dependencies:
  - US7
metadata:
  scope:
    backend: true
    frontend: false
  role: developer
  endpoint: null
  auth: false
  ui: false
scenarios:
  - name: Instalación global descarga el ZIP de GitHub
    given: que ejecuto el instalador en modo global (sin la opción -Local o --local)
    when: se inicia el proceso de instalación
    then: el script debe descargar el último ZIP de release (us-refinement.zip) desde las releases oficiales de GitHub, extraerlo en la carpeta centralizada ~/.hjagar/skills/us-refinement y crear los enlaces simbólicos o junctions correspondientes para los agentes.
  - name: Fallo de red o descarga del ZIP
    given: que no hay conexión a internet o el repositorio de GitHub no está accesible
    when: intento realizar una instalación global
    then: el instalador debe capturar el error de red, informar al usuario con un mensaje claro y abortar la instalación de forma segura sin dejar archivos corruptos en la carpeta de destino.
  - name: Modo local mantiene enlaces directos al código fuente
    given: que ejecuto el instalador con la opción -Local o --local
    when: se inicia la instalación
    then: el script debe omitir la descarga de internet y crear directamente los junctions o enlaces simbólicos apuntando al directorio de origen local, manteniendo el comportamiento actual para desarrollo.
-->
