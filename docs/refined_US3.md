## US3: Instalación Automatizada (Bootstrap/Installer)

**As a** desarrollador que quiere usar el skill por primera vez
**I want** contar con scripts de instalación sencillos (PowerShell para Windows, Bash para Linux/macOS) para clonar, configurar e instalar el skill en mi máquina con un solo comando
**So that** el proceso de onboarding sea rápido, automatizado y configure correctamente los entornos de múltiples agentes de IA (Antigravity, Claude Code, OpenCode).

### Acceptance criteria

**Scenario 1: Instalación local mediante enlaces simbólicos (Symlinks)**
- **Given** que el repositorio ya está clonado localmente y contiene el skill `us-refinement`
- **When** ejecuto el script de instalación (`install.ps1` o `install.sh`) indicando que quiero instalación local (modo desarrollo)
- **Then** el script debe crear enlaces simbólicos (symlinks) en los directorios de configuración de los agentes instalados en la máquina (Antigravity, Claude, OpenCode) apuntando a la ruta actual del repositorio.

**Scenario 2: Instalación global con copia de archivos**
- **Given** que se ejecuta el instalador en modo global (por defecto)
- **When** finaliza la descarga y copia de archivos
- **Then** el script debe crear una carpeta global del perfil (ej. `~/.config/us-refinement` o `~/.gemini/config/skills/us-refinement`), copiar allí los archivos del skill y configurar los enlaces simbólicos de los agentes apuntando a esa carpeta centralizada.

**Scenario 3: Validación de prerrequisito (Git)**
- **Given** que ejecuto el script de instalación
- **When** la herramienta `git` no está instalada en el sistema
- **Then** el script debe abortar inmediatamente la ejecución y mostrar un mensaje de error claro indicando que Git es un prerrequisito obligatorio.

**Scenario 4: Advertencia por falta de GitHub CLI (gh) (Nice-to-have)**
- **Given** que ejecuto el script de instalación
- **When** `git` está presente pero la herramienta `gh` no está instalada en el sistema
- **Then** el script debe imprimir una advertencia (warning) sugiriendo la instalación de `gh` como recomendación para el soporte de lectura de issues, pero continuar e instalar el skill de forma exitosa.

### Dependencies
- **US5: Zona Oculta para Contexto de IA en Markdown** (Requerido para generar la salida estructurada de los refinamientos)

### Technical scope
- Backend: Sí (scripts de instalación `install.ps1` y `install.sh`).
- Frontend: No.

### Assumptions / pending
- Se asume que el script detectará automáticamente qué agentes de IA están instalados leyendo la existencia de sus directorios de configuración globales (`~/.gemini/config`, `~/.claude`, `~/.config/opencode`).

<!-- [AI-DATA]
id: US3
type: feat
breaking: false
dependencies: [US5]
metadata:
  scope:
    backend: true
    frontend: false
  role: "developer"
  endpoint: "none"
  auth: "none"
  ui: "none"
scenarios:
  - name: "Local installation via symlinks"
    given: "the repository is cloned locally and containing a valid skill"
    when: "the developer executes the installation script with local/symlink flag"
    then: "it creates symbolic links in the global directories of configured agents pointing to the cloned repository folder"
  - name: "Global copy installation"
    given: "the repository contains the skill files"
    when: "the developer runs the installer in global mode"
    then: "it copies the skill files to a centralized directory and configures the agent paths to point to that directory"
  - name: "Validate Git prerequisite"
    given: "the developer runs the installation script"
    when: "Git is not installed on the system"
    then: "it aborts execution with a clear error message requesting Git installation"
  - name: "Warning for missing GitHub CLI"
    given: "the developer runs the installation script"
    when: "Git is installed but gh CLI is missing"
    then: "it logs a warning suggesting to install gh CLI, but continues and completes the installation"
-->
