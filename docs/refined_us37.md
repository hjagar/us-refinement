## US17: Version Bump Commit in Release Scripts (Release Automation Version Sync)

**As a** mantenedor del repositorio us-refinement
**I want** que los scripts de release actualicen el archivo `SKILL.md` en el espacio de trabajo, creen un commit de versión y lo empujen directamente a `main` antes de tagear la release
**So that** la versión declarada en el código y el tag de Git estén perfectamente sincronizados en la rama principal sin dejar archivos desactualizados en el repositorio

### Criterios de aceptación

**Scenario 1: Control de seguridad - Working tree sucio**
- Given un repositorio local con cambios sin commitear (working tree sucio)
- When el mantenedor ejecuta `Release-Repo.ps1` o `Release-Repo.sh`
- Then el script aborta inmediatamente con un mensaje de error explicativo
- And no realiza ningún commit, tag o release

**Scenario 2: Control de seguridad - Ejecución fuera de main**
- Given que el repositorio local está en una rama distinta a `main` (ej: `feat/us-16-multi-account`)
- When el mantenedor ejecuta `Release-Repo.ps1` o `Release-Repo.sh`
- Then el script aborta de inmediato con un mensaje de error explicativo
- And no realiza ningún commit, tag o release

**Scenario 3: Commit de versión y push directo exitoso**
- Given que el repositorio está en la rama `main` y limpio
- When el mantenedor ejecuta `Release-Repo.ps1` o `Release-Repo.sh` indicando una nueva versión (ej: `v1.2.0`)
- Then el script actualiza el marcador `<!-- version: v[\d\.]+ -->` en `SKILL.md` directamente en la raíz del repositorio
- And crea un commit local con el mensaje `chore(release): bump version to v1.2.0`
- And crea el tag `v1.2.0` apuntando a dicho commit
- And ejecuta `git push origin main --follow-tags` para subir el commit y el tag al remoto
- And genera el paquete ZIP usando los archivos locales actualizados

### Dependencias
- Ninguna

### Technical scope
- Backend: no
- Frontend: no
- Modificaciones en: `Release-Repo.ps1` y `Release-Repo.sh`

<!-- [AI-DATA]
id: US-37
type: feat
breaking: false
dependencies: []
metadata:
  scope:
    backend: false
    frontend: false
  role: "mantenedor del repositorio us-refinement"
  endpoint: "none"
  auth: "none"
  ui: "none"
scenarios:
  - name: "Pre-flight check - Dirty working tree"
    given: "workspace has uncommitted changes"
    when: "Release-Repo script is run"
    then: "it aborts with an error message and does not commit or tag"
  - name: "Pre-flight check - Non-main branch"
    given: "current git branch is not main"
    when: "Release-Repo script is run"
    then: "it aborts with an error message and does not commit or tag"
  - name: "Version bump commit and direct push on main"
    given: "workspace is on main branch and clean"
    when: "Release-Repo script is run"
    then: "it updates SKILL.md in-place, creates a commit chore(release): bump version to vX.Y.Z, tags it, pushes to origin main, and packages the ZIP"
-->
