## US7: Publicación Automatizada de Releases (Release Automation)

**As a** desarrollador / mantenedor del skill
**I want** contar con scripts de release (`Release-Repo.ps1` y `Release-Repo.sh`)
**So that** pueda validar los scripts, verificar el validador de esquemas, empaquetar el skill en un archivo ZIP y publicarlo en GitHub Releases de manera automatizada con un solo comando.

### Acceptance criteria

**Scenario 1: Quality Gate exitoso (Shellcheck + Python Validation)**
- **Given** que ejecuto el script de release (`Release-Repo.ps1` o `Release-Repo.sh`)
- **When** todos los scripts `.sh` pasan `shellcheck` sin errores, y `scripts/validate_refinement.py` retorna exitosamente (código 0) para el mock válido y falla (código 1) para el mock inválido
- **Then** el quality gate se considera aprobado y el script prosigue con el cálculo del incremento de versión.

**Scenario 2: Quality Gate fallido**
- **Given** que ejecuto el script de release
- **When** `shellcheck` reporta un problema o el validador de Python no retorna los códigos esperados para los archivos de pruebas (`tests/mock_valid_us.md` o `tests/mock_invalid_us.md`)
- **Then** el script aborta inmediatamente la ejecución con un código de error, sin crear tags ni modificar archivos.

**Scenario 3: Empaquetado del skill**
- **Given** que el quality gate fue exitoso y el usuario confirmó el release
- **When** se crea el archivo comprimido en `build/us-refinement.zip`
- **Then** debe incluir únicamente las carpetas y archivos necesarios (`SKILL.md`, `install.ps1`, `install.sh`, `uninstall.ps1`, `uninstall.sh`, `scripts/`, `docs/`, `tests/`), excluyendo carpetas de control de versiones (`.git`), configuraciones locales (`.gitignore`), especificaciones internas (`openspec/`), temporales de compilación (`build/`) y los propios scripts de release (`Release-Repo.*`).

**Scenario 4: Taggeo y publicación de la release en GitHub**
- **Given** que se generó el archivo ZIP
- **When** se aplica el tag de git localmente
- **Then** se empuja el tag al repositorio remoto y se invoca a `gh release create` para subir el zip y generar las notas de publicación automáticas (`--generate-notes`).

### Dependencies
- **US3: Instalación Automatizada (Bootstrap/Installer)**
- **US6: Desinstalación Automatizada (Uninstall/Cleanup)**

### Technical scope
- Backend: Sí (scripts de release `Release-Repo.ps1` y `Release-Repo.sh` en la raíz del repositorio).
- Frontend: No.

### Assumptions / pending
- Se asume que el desarrollador tiene instaladas las dependencias necesarias (`shellcheck`, `python` y la CLI de GitHub `gh` autenticada) en su sistema local.

<!-- [AI-DATA]
id: US7
type: feat
breaking: false
dependencies: [US3, US6]
metadata:
  scope:
    backend: true
    frontend: false
  role: "developer"
  endpoint: "none"
  auth: "none"
  ui: "none"
scenarios:
  - name: "Successful quality gate"
    given: "the release script is executed"
    when: "shellcheck passes on shell scripts, and validate_refinement.py succeeds on valid mock and fails on invalid mock"
    then: "the quality gate is marked as successful and it moves to the version bumping step"
  - name: "Failed quality gate"
    given: "the release script is executed"
    when: "shellcheck fails or validate_refinement.py returns unexpected exit codes on mocks"
    then: "the script aborts immediately without tagging or publishing"
  - name: "Skill packaging"
    given: "the quality gate passes and version is confirmed"
    when: "the zip file build/us-refinement.zip is generated"
    then: "it includes only essential files (SKILL.md, install, uninstall, scripts, docs, tests) and excludes .git, .gitignore, openspec, build, and the release scripts"
  - name: "Tagging and publishing on GitHub"
    given: "the zip file is created"
    when: "the git tag is applied and pushed"
    then: "it runs gh release create with the zip file and generates release notes"
-->
