## US2: Autodetección de Entorno y Herramientas

**As a** usuario del skill `us-refinement`
**I want** que el agente detecte automáticamente la disponibilidad de herramientas (`engram`, `gh` CLI, flujos SDD) en mi entorno de trabajo
**So that** adapte sus capacidades de almacenamiento, validación e integración de forma dinámica e interactiva.

### Acceptance criteria

**Scenario 1: Autodetección de Engram y consulta de almacenamiento**
- **Given** que el agente inicia el refinamiento o diseño técnico
- **When** se detecta la disponibilidad de `engram` en los servidores MCP activos
- **Then** el agente debe preguntar interactivamente al usuario cuál modo de almacenamiento prefiere, sugiriendo `engram` como la opción recomendada, pero permitiendo las siguientes opciones:
  - `engram` (solo memoria persistente)
  - `openspec` (solo archivos locales en la carpeta `openspec/`)
  - `hybrid` (sincronización en tiempo real tanto en archivos como en memoria)
  - `hybrid-delayed` (visualización y edición de archivos locales durante el proceso, persistiendo todo en Engram únicamente al finalizar la sesión).

**Scenario 2: Autodetección de gh CLI para integración con GitHub**
- **Given** que el refinamiento se inició sobre una issue de GitHub
- **When** el agente finaliza el refinamiento y verifica que `gh` CLI está instalado y autenticado
- **Then** debe ofrecer al usuario escribir el resultado de vuelta en GitHub (como comentario o editando la issue), realizando fallback a copiar/pegar en consola únicamente si la herramienta no está disponible.

**Scenario 3: Adaptación según la presencia de flujos SDD**
- **Given** que se ha completado el refinamiento de la historia
- **When** el agente detecta la presencia del directorio `.agents/` o `openspec/` y la configuración del flujo SDD
- **Then** debe proponer al usuario continuar directamente con el comando `/sdd-new` o la fase de exploración técnica, adaptando su recomendación final al entorno de desarrollo actual.

### Dependencies
- **None**

### Technical scope
- Backend: Sí (instrucciones dinámicas integradas en `SKILL.md` para guiar la toma de decisiones del agente en base a su contexto de herramientas).
- Frontend: No.

### Assumptions / pending
- Se asume que el agente tiene capacidad de listar sus servidores MCP para verificar la presencia de `engram` y ejecutar comandos rápidos de consola para probar la disponibilidad de `gh`.

<!-- [AI-DATA]
id: US2
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
  - name: Autodetección de Engram y consulta de almacenamiento
    given: que el agente inicia el refinamiento o diseño técnico
    when: se detecta la disponibilidad de engram en los servidores MCP activos
    then: el agente debe preguntar interactivamente al usuario cuál modo de almacenamiento prefiere, sugiriendo engram como la opción recomendada, pero permitiendo engram, openspec, hybrid y hybrid-delayed.
  - name: Autodetección de gh CLI para integración con GitHub
    given: que el refinamiento se inició sobre una issue de GitHub
    when: el agente finaliza el refinamiento y verifica que gh CLI está instalado y autenticado
    then: debe ofrecer al usuario escribir el resultado de vuelta en GitHub (como comentario o editando la issue), realizando fallback a copiar/pegar en consola únicamente si la herramienta no está disponible.
  - name: Adaptación según la presencia de flujos SDD
    given: que se ha completado el refinamiento de la historia
    when: el agente detecta la presencia del directorio .agents/ o openspec/ y la configuración del flujo SDD
    then: debe proponer al usuario continuar directamente con el comando /sdd-new o la fase de exploración técnica, adaptando su recomendación final al entorno de desarrollo actual.
-->
