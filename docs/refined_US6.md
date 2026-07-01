## US6: Desinstalación Automatizada (Uninstall/Cleanup)

**As a** desarrollador que ya no necesita el skill o quiere limpiar su máquina
**I want** contar con scripts de desinstalación (`uninstall.ps1` y `uninstall.sh`)
**So that** pueda remover completamente el skill y limpiar las junctions/symlinks de los agentes de IA de manera automatizada.

### Acceptance criteria

**Scenario 1: Confirmación de desinstalación**
- **Given** que ejecuto el script de desinstalación (`uninstall.ps1` o `uninstall.sh`)
- **When** el script solicita confirmación de borrado y respondo negativamente (`N` o `n`)
- **Then** el script debe abortar inmediatamente la desinstalación sin modificar ningún archivo o enlace en el sistema.

**Scenario 2: Limpieza de junctions/symlinks de agentes**
- **Given** que confirmo la desinstalación
- **When** el script procesa las rutas de configuración de los agentes (`~/.gemini`, `~/.claude`, `~/.config/opencode`)
- **Then** debe remover únicamente las carpetas `us-refinement` que sean junctions o enlaces simbólicos creados para este skill, sin afectar otras configuraciones del agente.

**Scenario 3: Eliminación de archivos y carpetas del skill centralizado**
- **Given** que confirmo la desinstalación
- **When** se remueve la carpeta del skill centralizado `~/.hjagar/skills/us-refinement`
- **Then** el script debe eliminar la carpeta padre de skills `~/.hjagar/skills` si queda vacía, y posteriormente eliminar `~/.hjagar` si queda vacía, evitando dejar carpetas vacías innecesarias.

**Scenario 4: Ejecución desde repositorio clonado**
- **Given** que ejecuto el script directamente desde un clon local del repositorio
- **When** el script detecta que su propia ruta está fuera de la instalación centralizada `~/.hjagar`
- **Then** debe remover las junctions/symlinks de los agentes pero no debe borrar la carpeta del repositorio actual, informando al usuario que debe eliminar el clon manualmente si así lo desea.

### Dependencies
- **US3: Instalación Automatizada (Bootstrap/Installer)**

### Technical scope
- Backend: Sí (scripts de desinstalación `uninstall.ps1` y `uninstall.sh` en la raíz del repositorio).
- Frontend: No.

### Assumptions / pending
- Se asume que el usuario tiene permisos suficientes en su terminal para eliminar los symlinks/junctions y directorios creados por el instalador.

<!-- [AI-DATA]
id: US6
type: feat
breaking: false
dependencies: [US3]
metadata:
  scope:
    backend: true
    frontend: false
  role: "developer"
  endpoint: "none"
  auth: "none"
  ui: "none"
scenarios:
  - name: "Confirm uninstallation"
    given: "the uninstallation script is executed"
    when: "the script asks for confirmation and the user responds with N"
    then: "it aborts immediately without modifying any files or links"
  - name: "Clean agent links"
    given: "the user confirms the uninstallation"
    when: "the script parses the agent config paths"
    then: "it removes only the junctions or symbolic links pointing to us-refinement without touching other agent configs"
  - name: "Clean central folders"
    given: "the user confirms the uninstallation"
    when: "the central folder at ~/.hjagar/skills/us-refinement is deleted"
    then: "it removes the parent directory ~/.hjagar/skills if it is empty, and then ~/.hjagar if it is empty"
  - name: "Run from local clone repository"
    given: "the script is executed from a cloned repository path"
    when: "the script detects that its path is not inside ~/.hjagar"
    then: "it cleans up the agent links but keeps the cloned repository intact, showing a manual deletion hint"
-->
