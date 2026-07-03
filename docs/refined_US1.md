## US1: Soporte Multi-Agente (Portabilidad de Formatos)

**As a** desarrollador que trabaja con diferentes agentes de IA (Antigravity/Gemini, Claude Code, OpenCode, Copilot CLI, Agents)
**I want** que el skill `us-refinement` sea cargado nativamente por todos los asistentes sin duplicar especificaciones
**So that** mantenga una única fuente de verdad (`SKILL.md`) y simplifique la instalación global multi-agente mediante enlaces simbólicos.

### Acceptance criteria

**Scenario 1: Vinculación global de todos los agentes soportados**
- **Given** que ejecuto el instalador (`install.ps1` o `install.sh`) en modo global
- **When** se procesa la instalación
- **Then** el script debe crear enlaces simbólicos o junctions en los directorios de skills de todos los agentes compatibles, apuntando centralizadamente a `~/.hjagar/skills/us-refinement`:
  - `~/.gemini/skills/us-refinement`
  - `~/.claude/skills/us-refinement`
  - `~/.config/opencode/skills/us-refinement`
  - `~/.copilot/skills/us-refinement`
  - `~/.agents/skills/us-refinement`

**Scenario 2: Vinculación en modo local para desarrollo**
- **Given** que ejecuto el instalador con la opción `-Local` o `--local`
- **When** se procesa la instalación
- **Then** el script debe crear los enlaces simbólicos o junctions para todos los agentes listados en el Escenario 1 apuntando directamente al clon local del repositorio.

**Scenario 3: Desinstalación limpia de todos los agentes**
- **Given** que ejecuto el desinstalador (`us-refinement-uninstall.ps1` o `us-refinement-uninstall.sh`)
- **When** confirmo la desinstalación
- **Then** el script debe remover de forma segura los enlaces de todos los agentes listados en el Escenario 1, sin tocar otras configuraciones globales de los agentes.

### Dependencies
- **None**

### Technical scope
- Backend: Sí (actualizar los arrays de rutas `$AgentPaths` en `install.ps1`, `install.sh`, `us-refinement-uninstall.ps1` y `us-refinement-uninstall.sh` para incluir las rutas globales de Copilot CLI y Agents).
- Frontend: No.

### Assumptions / pending
- Se asume que todos los agentes listados leen e interpretan el mismo estándar de archivos `SKILL.md` con frontmatter YAML (campos `name` y `description`).
- Las rutas para Copilot CLI y Agents son relativas al directorio `$HOME`.

<!-- [AI-DATA]
id: US1
type: feat
breaking: false
dependencies: []
metadata:
  scope:
    backend: true
    frontend: false
  role: developer
  endpoint: null
  auth: false
  ui: false
scenarios:
  - name: Vinculación global de todos los agentes soportados
    given: que ejecuto el instalador (install.ps1 o install.sh) en modo global
    when: se procesa la instalación
    then: el script debe crear enlaces simbólicos o junctions en los directorios de skills de todos los agentes compatibles, apuntando centralizadamente a ~/.hjagar/skills/us-refinement (Gemini, Claude, OpenCode, Copilot, Agents).
  - name: Vinculación en modo local para desarrollo
    given: que ejecuto el instalador con la opción -Local o --local
    when: se inicia la instalación
    then: el script debe crear los enlaces simbólicos o junctions para todos los agentes listados apuntando directamente al clon local del repositorio.
  - name: Desinstalación limpia de todos los agentes
    given: que ejecuto el desinstalador (us-refinement-uninstall.ps1 o us-refinement-uninstall.sh)
    when: confirmo la desinstalación
    then: el script debe remover de forma segura los enlaces de todos los agentes compatibles sin tocar otras configuraciones.
-->
